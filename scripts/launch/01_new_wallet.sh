#!/usr/bin/env bash

if [ -n $oldpath/../walletkey.ini ]; then
    #./keosd --config-dir ~/eosio-wallet --wallet-dir ~/eosio-wallet --http-server-address localhost:8879 --http-alias localhost:8900 > ~/eosio-wallet/stdout.log 2> ~/eosio-wallet/stderr.log &
    ./clio wallet create -n fio -f $oldpath/../walletkey.ini
else
    walletkey=$(head -n 1 $oldpath/../walletkey.ini)
    echo 'Using Password:' $walletkey
    sleep 0.5
    #./keosd --config-dir ~/eosio-wallet --wallet-dir ~/eosio-wallet --http-server-address localhost:8879 --http-alias localhost:8900 > ~/eosio-wallet/stdout.log 2> ~/eosio-wallet/stderr.log &
    ./clio wallet unlock -n fio --password $walletkey
fi