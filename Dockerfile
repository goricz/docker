#!/usr/bin/docker build .
#
# VERSION               1.0

FROM       debian:wheezy
MAINTAINER jirka@dutka.net

ENV HOSTNAME XoruX
ENV VM_IMAGE docker
ENV DEBIAN_FRONTEND noninteractive

# create file to see if this is the firstrun when started
RUN touch /firstrun

RUN apt-get update && apt-get dist-upgrade -y 

# install nesessary apps and libs
RUN apt-get update && apt-get install -yq\
    wget \
    supervisor \
    apache2 \
    ed \
    bc \
    librrdp-perl \
    libxml-simple-perl \
    libxml-libxml-perl \
    libcrypt-ssleay-perl \
    openssh-client \
    openssh-server \
    vim \
    rsyslog \
    sudo \
    less

#COPY *-setup.sh /
#COPY configs/spamassassin /etc/spamassasin
#RUN wget http://sourceforge.net/projects/postfixadmin/files/latest/download?source=files -O /postfixadmin.tgz
#RUN chown -R www-data.www-data /var/www

# Cleanup
RUN apt-get clean

# setup default user
RUN useradd lpar2rrd -U -s /bin/bash -m
RUN echo 'lpar2rrd:xorux4you' | chpasswd
RUN echo '%lpar2rrd ALL=(ALL) ALL' >> /etc/sudoers
RUN mkdir /home/stor2rrd \
    && mkdir /home/lpar2rrd/stor2rrd \
    && ln -s /home/lpar2rrd/stor2rrd /home/stor2rrd \
    && chown lpar2rrd /home/lpar2rrd/stor2rrd

# configure Apache
COPY configs/apache2 /etc/apache2/sites-available
COPY configs/apache2/htpasswd /etc/apache2/conf/

# change apache user to lpar2rrd
RUN sed -i 's/^export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=lpar2rrd/g' /etc/apache2/envvars

# adding web root
ADD www.tar.gz /var/
RUN chown -R www-data.www-data /var/www

# add product installations
ENV LPAR_VER 4.81
ENV STOR_VER 1.21

ADD lpar2rrd-$LPAR_VER.tar /home/lpar2rrd/
ADD stor2rrd-$STOR_VER.tar /home/stor2rrd/

EXPOSE 80 443 8162

COPY startup.sh /startup.sh
RUN chmod +x /startup.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY configs/crontab /var/spool/cron/crontabs/lpar2rrd
RUN chmod 600 /var/spool/cron/crontabs/lpar2rrd && chown lpar2rrd.crontab /var/spool/cron/crontabs/lpar2rrd

COPY *-setup.sh /

ENTRYPOINT [ "/startup.sh" ]
