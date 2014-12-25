FROM ubuntu:14.04
MAINTAINER Igor Lubimov <igor@checkio.org>

ENV NGINX_VERSION 1.7.9-1~trusty
ENV PG_MAJOR 9.3
ENV PG_VERSION 9.3.5-0ubuntu0.14.04.1

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
RUN update-locale LANG=en_US.UTF-8


RUN groupadd -r postgres && useradd -r -g postgres postgres

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7FCC7D46ACCC4CF8

RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
RUN echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list


RUN apt-get update
RUN apt-get install -y python python-dev python-pip
RUN apt-get install -y libpq-dev redis-server
RUN pip install pip-accel

#------------ NGINX --------------
RUN apt-get install -y nginx=${NGINX_VERSION}
#------------


#------------ POSTGRESQL --------------
RUN LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 apt-get install -y postgresql-common
RUN LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 apt-get install -y postgresql-$PG_MAJOR=$PG_VERSION postgresql-contrib-$PG_MAJOR=$PG_VERSION

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data


USER postgres

# Create a PostgreSQL role named ``checkio`` with ``checkio`` as the password and
# then create a database `docker` owned by the ``checkio`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER checkio WITH SUPERUSER PASSWORD 'checkio';" &&\
    createdb -O checkio checkio

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

# Add VOLUMEs to allow backup of config, logs and databases
# VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]
#------------

USER root

RUN rm -rf /var/lib/apt/lists/*


EXPOSE 80 443 5432
