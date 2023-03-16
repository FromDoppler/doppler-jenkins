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

FROM jenkins/jenkins:2.395-jdk11 as final
RUN ls
