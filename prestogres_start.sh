#!/bin/bash

sudo iptables -t nat -A OUTPUT -p tcp --dport 8889 -j REDIRECT --to-port 12345
echo ""
echo "Checking proxy:"
echo "curl --socks4 ${PROXY_SERVER}:${PROXY_PORT} google.co.uk ..."
curl --socks4 ${PROXY_SERVER}:${PROXY_PORT} google.co.uk
echo ""
echo "curl --socks4 ${PROXY_SERVER}:${PROXY_PORT} $PRESTO_SERVER/ui ..."
curl --socks4 ${PROXY_SERVER}:${PROXY_PORT} $PRESTO_SERVER/ui
echo ""
echo "cat /etc/hosts:"
cat /etc/hosts
echo ""
echo "redsocks -c /etc/redsocks.conf ..."
redsocks -c /etc/redsocks.conf
echo "Prestogres stuff:"
sleep 5
su - postgres -c "prestogres-ctl postgres -D $PGDATA 2>&1 > /tmp/postgres.log &"
sleep 5
prestogres-ctl migrate
prestogres-ctl pgpool 
