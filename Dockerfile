FROM ubuntu:latest
MAINTAINER Mike Kruk <mike@ripeworks.com>

RUN apt-get -y update
RUN apt-get -y upgrade

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y install curl build-essential libxml2-dev libxslt-dev git
RUN curl -L https://www.opscode.com/chef/install.sh | bash
RUN echo "gem: --no-ri --no-rdoc" > ~/.gemrc

RUN /opt/chef/embedded/bin/gem install berkshelf

ADD . /chef
RUN cd /chef && /opt/chef/embedded/bin/berks install --path /chef/cookbooks
RUN chef-solo -c /chef/solo.rb -j /chef/solo.json
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

CMD ["nginx"]

## generate ssl cert
# RUN openssl req -new -x509 -days 1000 -nodes -out "/etc/ssl/certs/dovecot.pem" -keyout "/etc/ssl/private/dovecot.pem"

EXPOSE 22 25 80 110 143 465 993 995
