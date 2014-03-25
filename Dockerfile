FROM ubuntu:latest
MAINTAINER Mike Kruk <mike@ripeworks.com>

RUN echo "deb http://archive.ubuntu.com/ubuntu quantal main universe" > /etc/apt/sources.list
RUN apt-get -y update

ENV DEBIAN_FRONTEND noninteractive

# Config
ENV DOMAIN example.org
ENV HOSTNAME mail.$DOMAIN

# run echo "$HOSTNAME" > /etc/hostname
RUN echo "$DOMAIN" > /etc/mailname

# Disable upstart
# RUN dpkg-divert --local --rename --add /sbin/initctl && ln -s /bin/true /sbin/initctl

# Generate SSL certificate
RUN apt-get install -y --force-yes ssl-cert

ADD ./aliases /etc/postfix/virtual
ADD ./domains /etc/postfix/virtual-mailbox-domains

# MTA (postfix)
RUN apt-get install -y --force-yes postfix heirloom-mailx sasl2-bin libsasl2-2
ADD ./conf/postfix.main.cf /etc/postfix/main.cf
ADD ./conf/postfix.master.cf.append /etc/postfix/master-additional.cf
RUN cat /etc/postfix/master-additional.cf >> /etc/postfix/master.cf

# todo: this could probably be done in one line
RUN mkdir /etc/postfix/tmp; awk < /etc/postfix/virtual '{ print $2 }' > /etc/postfix/tmp/virtual-receivers
RUN sed -r 's,(.+)@(.+),\2/\1/,' /etc/postfix/tmp/virtual-receivers > /etc/postfix/tmp/virtual-receiver-folders
RUN paste /etc/postfix/tmp/virtual-receivers /etc/postfix/tmp/virtual-receiver-folders > /etc/postfix/virtual-mailbox-maps

RUN chown -R postfix:postfix /etc/postfix
RUN postmap /etc/postfix/virtual
RUN postmap /etc/postfix/virtual-mailbox-maps

## sasl
# RUN echo "\
# START=yes\
# OPTIONS=\"-c -m /var/spool/postfix/var/run/saslauthd\"\
# " >> /etc/default/saslauthd
# RUN mkdir -p /var/spool/postfix/var/run/saslauthd
# RUN chown -R root:sasl /var/spool/postfix/var/run/saslauthd
# RUN adduser postfix sasl
# RUN service saslauthd restart
# RUN echo "pwcheck_method: saslauthd" > /etc/postfix/sasl/smtpd.conf

RUN groupadd -g 5000 vmail
RUN useradd -g vmail -u 5000 vmail -d /srv/vmail -m
RUN chown -R vmail:vmail /srv/vmail
RUN chmod u+w /srv/vmail

# IMAP
RUN apt-get -y install dovecot-imapd dovecot-sieve

ADD ./conf/dovecot.mail /etc/dovecot/conf.d/10-mail.conf
ADD ./conf/dovecot.ssl /etc/dovecot/conf.d/10-ssl.conf
ADD ./conf/dovecot.auth /etc/dovecot/conf.d/10-auth.conf
ADD ./conf/dovecot.master /etc/dovecot/conf.d/10-master.conf
ADD ./conf/dovecot.lda /etc/dovecot/conf.d/15-lda.conf
ADD ./conf/dovecot.imap /etc/dovecot/conf.d/20-imap.conf
# add verbose logging
ADD ./conf/dovecot.logging /etc/dovecot/conf.d/10-logging.conf

ADD ./passwords /etc/dovecot/passwd

VOLUME /srv/vmail


EXPOSE 25 143 587
ENTRYPOINT chown -R vmail:vmail /srv/vmail; service rsyslog start; service postfix start; dovecot -F
