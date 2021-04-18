#!/bin/bash

EVENT_UUID=$1
if [[ -z $EVENT_UUID ]]; then
     EVENT_UUID = '_ping';
fi

SFDC_HOST=sandbox-btdev-developer-edition.cs43.force.com
NAMESPACE=/gbutt
curl -X POST \
     -H "Content-Type: application/json" \
     -d '{"firstName": "Prince", "lastName": "Humperdink", "email": "phumperdink@florin.co", "isRegistered": true}' \
     https://${SFDC_HOST}/services/apexrest${NAMESPACE}/events/v1/event/${EVENT_UUID}/register