# cSpell: enableCompoundWords
FROM koalaman/shellcheck-alpine:v0.9.0 as verify-sh
WORKDIR /src
COPY ./*.sh ./
RUN shellcheck -e SC1091,SC1090 ./*.sh

FROM node:19 AS verify-format
WORKDIR /src
COPY package.json yarn.lock ./
RUN yarn
COPY . .
ENV CI=true
RUN yarn verify-format && yarn verify-spell

FROM jenkins/jenkins:2.397-jdk17 as final
# Keep root user because I need it to access to /var/run/docker.sock
# hadolint ignore=DL3002
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
  lsb-release=11.1.0 \
  gitlint=0.15.0-1 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
  https://download.docker.com/linux/debian/gpg
RUN echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
RUN apt-get update && apt-get install -y --no-install-recommends docker-ce-cli=5:23.0.1-1~debian.11~bullseye \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
# USER jenkins

# Plugin notes:
# * configuration-as-code:1613.vb_e54b_445ed6f has issues: https://github.com/jenkinsci/configuration-as-code-plugin/issues/2236
RUN jenkins-plugin-cli --plugins \
  blueocean:1.27.3 \
  github-oauth:0.39 \
  basic-branch-build-strategies:71.vc1421f89888e \
  github-scm-trait-notification-context:1.1 \
  job-dsl:1.83 \
  configuration-as-code:1569.vb_72405b_80249

# USER root
ARG version=unknown
RUN echo $version > /version.txt
# USER jenkins
