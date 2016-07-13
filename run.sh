#!/bin/bash

[ -z "${SERVER_HOSTNAME}" ]    && echo "SERVER_HOSTNAME is not set"     && exit 1
[ -z "${SMTP_SERVER}" ]        && echo "SMTP_SERVER is not set"         && exit 1
[ -z "${SMTP_USERNAME}" ]      && echo "SMTP_USERNAME is not set"       && exit 1
[ -z "${SMTP_PASSWORD}" ]      && echo "SMTP_PASSWORD is not set"       && exit 1
[ -z "${DOMAINS_TO_DISCARD}" ] && echo "DOMAINS_TO_DISCARD is not set"  && exit 1

#Get the domain from the server host name
DOMAIN=`echo $SERVER_HOSTNAME |awk -F. '{$1="";OFS="." ; print $0}' | sed 's/^.//'`

## /etc/postfix/main.cf

#Comment default mydestination, we will set it bellow
sed -i -e '/mydestination/ s/^#*/#/' /etc/postfix/main.cf

echo "myhostname=$SERVER_HOSTNAME"  >> /etc/postfix/main.cf
echo "mydomain=$DOMAIN"  >> /etc/postfix/main.cf
echo 'mydestination=$myhostname'  >> /etc/postfix/main.cf
echo 'myorigin=$mydomain'  >> /etc/postfix/main.cf
echo "transport_maps = hash:/etc/postfix/transport" >> /etc/postfix/main.cf
echo "smtp_use_tls=yes" >> /etc/postfix/main.cf
echo "smtp_sasl_auth_enable = yes" >> /etc/postfix/main.cf
echo "smtp_sasl_password_maps = static:$SMTP_USERNAME:$SMTP_PASSWORD" >> /etc/postfix/main.cf
echo "smtp_sasl_security_options = noanonymous" >> /etc/postfix/main.cf
echo "smtp_tls_security_level = may" >> /etc/postfix/main.cf
echo "debug_peer_list = funkifake.com" >> /etc/postfix/main.cf
echo "debug_peer_level = 2" >> /etc/postfix/main.cf

## /etc/postfix/transport

echo "localhost discard:" >> /etc/postfix/transport
echo "localhost.localdomain discard:" >> /etc/postfix/transport

for domain in $(echo $DOMAINS_TO_DISCARD | tr ":" "\n")
do
  echo "$domain discard:" >> /etc/postfix/transport
done

echo "* relay:[$SMTP_SERVER]:587" >> /etc/postfix/transport

postmap /etc/postfix/transport

supervisord
