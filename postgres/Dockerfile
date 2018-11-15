FROM postgres:latest
#FROM postgres:9.3

LABEL maintainer="bubbkis <bubbkis@gmail.com>"

COPY ./conf/postgresql.conf /var/lib/postgresql/data/postgresql.conf

RUN localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8

ENV LANG ja_JP.utf8

CMD ["postgres"]

EXPOSE 5432
