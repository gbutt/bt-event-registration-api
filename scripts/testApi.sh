#!/bin/bash

EVENT_UUID=$1
if [[ -z $EVENT_UUID ]]; then
     EVENT_UUID='_ping'
fi

SFDC_HOST=sandbox-btdev2-developer-edition.cs95.force.com
# NAMESPACE=/your-namespace
NAMESPACE=''
URL="https://${SFDC_HOST}/services/apexrest${NAMESPACE}/events/v1/event/${EVENT_UUID}/register"
echo posting to $URL
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"firstName": "Prince", "lastName": "Humperdink", "email": "phumperdink@florin.co", "isRegistered": true}' \
     "$URL"