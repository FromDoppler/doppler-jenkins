# cSpell: enableCompoundWords
FROM koalaman/shellcheck-alpine:v0.9.0 as verify-sh
WORKDIR /src
COPY ./*.sh ./
RUN shellcheck -e SC1091,SC1090 ./*.sh

FROM node:21 AS verify-format
WORKDIR /src
COPY package.json yarn.lock ./
RUN yarn
COPY . .
ENV CI=true
RUN yarn verify-format && yarn verify-spell

FROM jenkins/jenkins:2.417-jdk17 as final
# Keep root user because I need it to access to /var/run/docker.sock
# hadolint ignore=DL3002
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    lsb-release=11.1.0 \
    gitlint=0.15.0-1 \
    gettext-base=0.21-4 \
    python3-pip=20.3.4-4+deb11u1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && pip3 install --no-cache-dir awscli==1.27.134
RUN curl -fsSLo sops.deb \
  https://github.com/mozilla/sops/releases/download/v3.7.1/sops_3.7.1_amd64.deb \
  && dpkg -i sops.deb \
  && rm sops.deb
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y --no-install-recommends \
    docker-ce-cli=5:23.0.2-1~debian.11~bullseye \
    docker-buildx-plugin=0.10.4-1~debian.11~bullseye \
    docker-compose-plugin=2.17.3-1~debian.11~bullseye \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# USER jenkins

RUN jenkins-plugin-cli --plugins \
  blueocean:1.27.5 \
  ws-cleanup:0.45 \
  pipeline-stage-view:2.33 \
  docker-workflow:563.vd5d2e5c4007f \
  github-oauth:588.vf696a_350572a_ \
  basic-branch-build-strategies:81.v05e333931c7d \
  github-scm-trait-notification-context:1.1 \
  job-dsl:1.84 \
  configuration-as-code:1670.v564dc8b_982d0

# USER root
ARG version=unknown
RUN echo $version > /version.txt
# USER jenkins
