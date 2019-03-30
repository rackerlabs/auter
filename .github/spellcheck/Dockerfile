FROM debian:latest

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y aspell aspell-en

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

LABEL "name"="spellcheck"
LABEL "maintainer"="Nick Rhodes <nrhodes91@gmail.com>"
LABEL "version"="0.0.1"

LABEL "com.github.actions.name"="SpellCheck"
LABEL "com.github.actions.description"="Spell checker"
LABEL "com.github.actions.icon"="book-open"
LABEL "com.github.actions.color"="green"
