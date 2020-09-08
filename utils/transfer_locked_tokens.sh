#!/bin/bash

# Script to sign and pack a transaction.
#ACCOUNT r41zuwovtn44   --casey@dapix
#OWNER KEYS
#PUBLIC FIO5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82
#PRIVATE 5JLxoeRoMDGBbkLdXJjxuh3zHsSS7Lg6Ak9Ft8v8sSdYPkFuABF

#ACCOUNT htjonrkf1lgs    -- adam@dapix
#OWNER KEYS
#PUBLIC FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN
#PRIVATE 5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz

#non existingaccount
#Private key: 5J7ocyimcfcR6LMQmC43uo7JUBS5eRPbTwiJuH4qP77tToSZTVJ
#Public key: FIO6yfrigXgsnPGkYBox8P5xDgVwRxuoxtejJDJfpc58VwZGVK4tx
#FIO Public Address (actor name): ncmmejvfrgyb


nPort=8889
wPort=9899
hostname="localhost"

if [ -z "$1" ]; then
    domain="casey@dapix"
else
    domain=$1
fi

echo ------------------------------------------


fiopubkey="FIO7uRvrLVrZCbCM2DtCgUMospqUMnP3JUC1sKHA8zNoF835kJBvN"

fioactor=`programs/clio/clio convert fiokey_to_account $fiopubkey`

# use this public key for the account doesnt exist yet use case EOS6ZnHNENybLCe6n221dgTbEYgizrWG4NGot6h5cdtPk5XXjxtez
# use this public key for teh account exists already use case EOS5oBUYbtGTxMS66pPkjC2p8pbA3zCtc8XD4dq9fMut867GRdh82
echo ------------------------------------------
dataJson="{\"payee_public_key\": \"FIO6yfrigXgsnPGkYBox8P5xDgVwRxuoxtejJDJfpc58VwZGVK4tx\",\"can_vote\": 0,\"periods\": [{\"duration\": 120,\"percent\": 50.0},{\"duration\":240,\"percent\":25.0},{\"duration\": 360,\"percent\": 25.0}],\"amount\": 100000000000,\"max_fee\":4000000000,\"actor\": \"${fioactor}\",\"tpid\": \"adam@dapix\",}"

expectedPackedData=056461706978104208414933a95b
cmd="programs/clio/clio --no-auto-keosd --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort  convert pack_action_data fio.token trnsloctoks '${dataJson}'"
echo CMD: $cmd
actualPackedData=`eval $cmd`
ret=$?
echo PACKED DATA: $actualPackedData
if [[ $ret != 0 ]]; then  exit $ret; fi
echo ------------------------------------------

headBlockTime=`programs/clio/clio --no-auto-keosd --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort get info | grep head_block_time | awk '{print substr($2,2,length($2)-3)}'`
echo HEAD BLOCK TIME: $headBlockTime

cmd="date -d \"+1 hour $headBlockTime\" \"+%FT\"%T"
if [[ "$OSTYPE" == "darwin"* ]]; then
    cmd="date -j -v+1H -f \"%Y-%m-%dT%H:%M:%S.\" \"$headBlockTime\" \"+%FT\"%T"
fi
echo CMD: $cmd
expirationStr=`eval $cmd`
echo EXPIRATION: $expirationStr

cmd="programs/clio/clio --no-auto-keosd --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort get info | grep last_irreversible_block_num | grep -o '[0-9]\+'"
echo CMD: $cmd
lastIrreversibleBlockNum=`eval $cmd`
#lastIrreversibleBlockNum=`programs/clio/clio --no-auto-keosd --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort get info | grep last_irreversible_block_num | grep -o '[[:digit:]]*'`
echo LAST IRREVERSIBLE BLOCK NUM: $lastIrreversibleBlockNum

cmd="programs/clio/clio --no-auto-keosd --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort get block $lastIrreversibleBlockNum | grep -m 1 -e ref_block_prefix | grep -o '[0-9]\+'"
echo CMD: $cmd
refBlockPrefix=`eval $cmd`
#refBlockPrefix=`programs/clio/clio --no-auto-keosd --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort get block $lastIrreversibleBlockNum | grep -m 1 -e ref_block_prefix | grep -o '[[:digit:]]*'`
echo REF BLOCK PREFIX: $refBlockPrefix
echo ------------------------------------------

# Unsigned request
unsignedRequest='{
    "chain_id": "cf057bbfb72640471fd910bcb67639c22df9f92470936cddc1ade0e2f2e7dc4f",
    "expiration": "'${expirationStr}'",
    "ref_block_num": '${lastIrreversibleBlockNum}',
    "ref_block_prefix": '${refBlockPrefix}',
    "max_net_usage_words": 0,
    "max_cpu_usage_ms": 0,
    "delay_sec": 0,
    "context_free_actions": [],
    "actions": [{
        "account":"fio.token",
        "name": "trnsloctoks"
        "authorization":[{
             "actor":"'${fioactor}'",
             "permission":"active"
        }]
    "data": "'${actualPackedData}'"
      }
    ],
    "transaction_extensions": [],
    "signatures": [],
    "context_free_data": []
  }
'
# echo $unsignedRequest

# Sign request
expectedSignedRequest='{
    "signatures":["SIG_K1_Kcax7imeZM2nK3di7eZRZ5Y82eyxRHGE4gx7CT1Rky1JTVVmKCwytFLMTjg888B4RiwjhoCwk5pXndywg1pRxj8RCGqKyy",
                    "SIG_K1_K5FLUb7y2nq5EJjTRGDr5G2iFpEasX2qmrHbdexJDbYiYmiXo9b1YLTXz73b9VE6ipxs5gRtMooRyFUx9ucKQ8jBjYsR3u"],
"context_free_data":[]}'


cmd="./programs/clio/clio --no-auto-keosd --url http://localhost:8889  --wallet-url http://localhost:9899 sign '$unsignedRequest' -k 5JCpqkvsrCzrAC3YWhx7pnLodr3Wr9dNMULYU8yoUrPRzu269Xz"
echo CMD: $cmd
actualSignedResponse=`eval $cmd`
ret=$?
echo SIGNED RESPONSE: $actualSignedResponse
if [[ $ret != 0 ]]; then  exit $ret; fi
echo ------------------------------------------

# Pack request
expectedPackedResponse='{
    "signatures": [
      "SIG_K1_K5C3qWUzKJ3ciWQSe98vJF5jK5enmaFguaac5FYZn5sMSgk5shu86xSsELAqePvEquTjm1JsoaeKWFjEP4hT2sJyZRA8G3",
      "SIG_K1_K3d5zYXdsatBW5GZCrSV5c8TrwghGiv5xJR7RJ2XMiZBagDr5njgYrEMCVnLm4aNV9oFSWcCMUQfeaSWL2yZveJdpBsme4" ],
    "compression": "none",
    "packed_context_free_data": "",
    "packed_trx": "46c8125c8d00783accd500000000010000000000000000a0a4995765ec98ba000c036f6369104208414933a95b00" }'


cmd="programs/clio/clio --no-auto-keosd --verbose --url http://$hostname:$nPort --wallet-url http://$hostname:$wPort convert pack_transaction '$actualSignedResponse'"
echo CMD: $cmd
actualPackedResponse=`eval $cmd`
ret=$?
echo PCK RSP: $actualPackedResponse
if [[ $ret != 0 ]]; then  exit $ret; fi
echo ------------------------------------------

exit 0
