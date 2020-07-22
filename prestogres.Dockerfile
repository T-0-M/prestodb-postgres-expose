FROM ubuntu:16.04

ARG PGDATA
ARG PRESTO_CATALOG
ARG PRESTO_SERVER
ARG PRESTOGRES_VERSION
ARG PROXY_PORT
ARG PROXY_SERVER

ENV PGDATA $PGDATA
ENV PRESTO_CATALOG $PRESTO_CATALOG
ENV PRESTO_SERVER $PRESTO_SERVER
ENV PRESTOGRES_VERSION $PRESTOGRES_VERSION
ENV PROXY_PORT $PROXY_PORT
ENV PROXY_SERVER $PROXY_SERVER

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8 #

# Add PostgreSQL's repository. It contains the most recent stable release.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list #s

#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
	apt-get install -qy apt-utils

RUN	apt-get install -qy python-software-properties \
						software-properties-common \
						postgresql-9.6 \
						postgresql-contrib-9.6 \
						postgresql-server-dev-9.6 \
						postgresql-plpython-9.6 \
						gcc \
						make \
						libssl-dev \
						libpcre3-dev \
						openssh-server \
						python \
						supervisor \
						iptables \
						redsocks \
						curl \
						lynx \
						sudo \
						nano

ADD https://github.com/agarstang/prestogres/archive/master.tar.gz prestogres.tar.gz

RUN tar xvfz prestogres.tar.gz && cd prestogres-master && \
	./configure --program-prefix=prestogres- && \
	make && \
	make install

RUN mkdir /var/lib/postgres && \
	chown -R postgres:postgres /var/lib/postgres

USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" && \
    createdb -O docker docker

RUN echo ${PGDATA}
RUN echo $PGDATA

RUN prestogres-ctl create ${PGDATA}

USER root

COPY redsocks.conf /etc/redsocks.conf

RUN sed -i "s/vPROXY-SERVER/$PROXY_SERVER/g" /etc/redsocks.conf && \
	sed -i "s/vPROXY-PORT/$PROXY_PORT/g" /etc/redsocks.conf && \
	/etc/init.d/redsocks restart

COPY prestogres.conf /usr/local/etc/prestogres.conf

RUN sed -i "s/vPRESTO-SERVER/$PRESTO_SERVER/g" /usr/local/etc/prestogres.conf && \
	sed -i "s/vPRESTO-CATALOG/$PRESTO_CATALOG/g" /usr/local/etc/prestogres.conf

COPY prestogres_hba.conf /usr/local/etc/prestogres_hba.conf

RUN sed -i "s/vPRESTO-SERVER/$PRESTO_SERVER/g" /usr/local/etc/prestogres_hba.conf && \
	sed -i "s/vPRESTO-CATALOG/$PRESTO_CATALOG/g" /usr/local/etc/prestogres_hba.conf

COPY prestogres_start.sh /prestogres_start.sh

CMD ["/prestogres_start.sh"]
