#!/bin/bash

sudo iptables -t nat -A OUTPUT -p tcp --dport 8889 -j REDIRECT --to-port 12345

echo "Prestogres Configuration:"

su - postgres -c "prestogres-ctl postgres -D $PGDATA 2>&1 > /tmp/postgres.log &"
sleep 5
prestogres-ctl migrate
prestogres-ctl pgpool 


