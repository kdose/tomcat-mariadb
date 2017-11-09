FROM mariadb:10

ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN mkdir -p "$CATALINA_HOME"

ENV TOMCAT_MAJOR 8
ENV TOMCAT_VERSION 8.5.23
ENV TOMCAT_SHA1 1ba27c1bb86ab9c8404e98068800f90bd662523c

ENV TOMCAT_TGZ_URLS \
# https://issues.apache.org/jira/browse/INFRA-8753?focusedCommentId=14735394#comment-14735394
        https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
# if the version is outdated, we might have to pull from the dist/archive :/
        https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
        https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz \
        https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz

ENV TOMCAT_ASC_URLS \
        https://www.apache.org/dyn/closer.cgi?action=download&filename=tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
# not all the mirrors actually carry the .asc files :'(
        https://www-us.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
        https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc \
        https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc

RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends openjdk-7-jre; \
        rm -rf /var/lib/apt/lists/*

RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends wget; \
        rm -rf /var/lib/apt/lists/*; \
        \
        cd $CATALINA_HOME; \
        \
        success=; \
        for url in $TOMCAT_TGZ_URLS; do \
                if wget -O tomcat.tar.gz "$url"; then \
                        success=1; \
                        break; \
                fi; \
        done; \
        [ -n "$success" ]; \
        \
        echo "$TOMCAT_SHA1 *tomcat.tar.gz" | sha1sum -c -; \
        \
        success=; \
        for url in $TOMCAT_ASC_URLS; do \
                if wget -O tomcat.tar.gz.asc "$url"; then \
                        success=1; \
                        break; \
                fi; \
        done; \
        [ -n "$success" ]; \
        \
        tar -xvf tomcat.tar.gz --strip-components=1; \
        rm bin/*.bat; \
        rm tomcat.tar.gz*; \
        apt-get purge -y --auto-remove wget; \
# sh removes env vars it doesn't support (ones with periods)
# https://github.com/docker-library/tomcat/issues/77
        find ./bin/ -name '*.sh' -exec sed -ri 's|^#!/bin/sh$|#!/usr/bin/env bash|' '{}' +

ENV MYSQL_RANDOM_ROOT_PASSWORD 1
ENV WAIT_FOR_DB_INIT 5

EXPOSE 3306 8080

COPY run.sh /

CMD [ "/run.sh" ]
