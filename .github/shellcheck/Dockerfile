FROM centos:latest

LABEL "name"="shellcheck"
LABEL "maintainer"="Nick Rhodes <nrhodes91@gmail.com>"
LABEL "version"="0.0.1"

LABEL "com.github.actions.name"="ShellCheck"
LABEL "com.github.actions.description"="Run koalaman's ShellCheck"
LABEL "com.github.actions.icon"="terminal"
LABEL "com.github.actions.color"="black"

RUN yum update -y \
    && yum install -y epel-release \
    && yum install -y ShellCheck

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
