#!/bin/bash

# See options at: http://www.hotspotsystem.com/apidocs/api/reference/
# And at: http://www.hotspotsystem.com/apidocs-v1/

while [[ $# -gt 0 ]]
do
key="$1"

# Defaults
FLAGVOUCHER=0
FLAGGENERATE=0

case $key in
    -k|--key)
    KEY="$2"
    shift # past argument
    ;;
    -i|--id)
    ID="$2"
    shift # past argument
    ;;
    -v|--vouchers)
    FLAGVOUCHER=1
    ;;
    -g|--generate)
    FLAGGENERATE=1
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

if [[ -n $1 ]]; then
    echo "##################"
    echo "Last line of file specified as non-opt/last argument:" $1
    echo "##################"
    echo ""
fi

echo "KEY         = ${KEY}"
echo "ID          =  ${ID}"
echo "VOUCHERFLAG = ${FLAGVOUCHER}"
echo "GENERATEFLAG = ${FLAGGENERATE}"
echo ""

# Check for missing key
if [ -z "$KEY" ]; then
    echo ERROR: "Please supply the API key with -k option." 1>&2
    exit 1
fi

# Define variables
ROOT1='https://api.hotspotsystem.com/v1.0'
ROOT2='https://api.hotspotsystem.com/v2.0'

#Write functions
function api_vouchers {
    echo "Use the GET /vouchers API"
    URL=${1}'/vouchers'
    echo "curl -H 'sn-apikey: $KEY' -X GET $URL"
    echo ""
    OUT=`curl -H "sn-apikey: $KEY" -X GET $URL`
    echo $OUT | jq '[.items]'
    echo $OUT | jq 'keys'
    echo $OUT | jq '[.metadata]'
    echo ""
}

function api_locations_locationId_vouchers_v1 {
    echo "GET /locations/{locationId}/vouchers for id:$ID"
    URL=${1}'/locations/'${ID}'/vouchers.json'
    LIMIT=100
    echo "curl -G -d 'limit=$LIMIT' -X GET -u ${KEY}:x $URL"
    echo ""
    OUT=`curl -G -d "limit=$LIMIT" -X GET -u ${KEY}:x $URL`
    echo $OUT | jq '[.results]'
    echo -e "\n"
    # Possible keys
    # voucher_code, validity, price_enduser, usage_exp
    # serial, simultaneous_use,limit_dl, limit_ul, limit_tl
    echo $OUT | jq '[.results][][] | "Code:\(.voucher_code), Validity:\(.validity) min/H, price:\(.price_enduser), Time left:\(.usage_exp)"' 
    echo -e "\n"
    echo $OUT | jq 'keys'
    echo $OUT | jq '[.metadata]'
    echo ""
}

function api_locations_locationId_vouchers_v2 {
    echo "GET /locations/{locationId}/vouchers for id:$ID"
    URL=${1}'/locations/'${ID}'/vouchers'
    LIMIT=100
    echo "curl -G -d 'limit=$LIMIT' -H 'sn-apikey: $KEY' -X GET $URL"
    echo ""
    OUT=`curl -G -d "limit=$LIMIT" -H "sn-apikey: $KEY" -X GET $URL`
    echo $OUT | jq '[.items]'
    echo $OUT | jq 'keys'
    echo $OUT | jq '[.metadata]'
    echo ""
}

function api_locations_locationId_generate_voucher_v1 {
    echo "GET /locations/{locationId}/generate/voucher for id:$ID"
    URL=${1}'/locations/'${ID}'/generate/voucher.json'
    echo $URL
    PACKAGE=7
    echo "curl -G -d 'package=$PACKAGE' -X GET -u ${KEY}:x $URL"
    echo ""
    OUT=`curl -G -d "package=$PACKAGE" -X GET -u ${KEY}:x $URL`
    echo $OUT | jq 'keys'
    echo $OUT | jq '.'
    echo $OUT | jq '[.access_code]'
}

#Check provided flags to execute
if [ "$FLAGVOUCHER" -eq "1" ]; then
    if [ -z "$ID" ]; then
        api_vouchers $ROOT2
    else
        api_locations_locationId_vouchers_v1 $ROOT1
        #api_locations_locationId_vouchers_v2 $ROOT2
    fi
fi

if [ "$FLAGGENERATE" -eq "1" ]; then
    echo 1
    if [ -z "$ID" ]; then
        echo 2
        echo ERROR: "Please supply the location ID where the voucher credit will be deducted from with -i option." 1>&2
    else
        echo "jhe"
        api_locations_locationId_generate_voucher_v1 $ROOT1
    fi
fi