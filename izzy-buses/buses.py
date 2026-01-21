#!/usr/bin/env python3

from datetime import datetime, timedelta
from lxml import etree
from zeep import Client
from zoneinfo import ZoneInfo
import json
import logging
import os
import re
import requests
import sys

logging.basicConfig(filename="buses.log", level=logging.INFO)
hour = datetime.now(ZoneInfo("America/Los_Angeles")).hour

ROUTE = "51B"
STOP = "55593"

def filter_predictions(predictions):
    # Prior to 9/26/2025, this only returned the requested route
    # Now it returns every route?
    fp = []
    for p in predictions:
        if p['rt'] == ROUTE:
            fp.append(p) 
    return fp

if hour != 7:
    sys.exit()

url = "https://api.actransit.org/transit/actrealtime/prediction"
params = {
    "stpid": STOP,
    "rt": ROUTE,
    "token": os.environ["BUS_SECRET"],
}

response = requests.get(url, params=params)
if response.ok:
    data = response.json()
    predictions = data.get("bustime-response", {}).get("prd", [])
    messages = [f"Bus {p['vid']} in {p['prdctdn']} min." for p in filter_predictions(predictions)]
    bus_body = ' '.join(messages)
else:
    raise RuntimeError(response)

matches = re.findall( r'Bus (\d+) in (\d+) min', bus_body)
now = datetime.now() 
sms_body = str()
for match in matches:
    busmins = timedelta(minutes=int(match[1]))
    sms_body += "Bus " + match[0] + " at " + (now+busmins).strftime("%H:%M") +"\n"

client = Client('./server.wsdl')
sms_type = client.get_type('ns0:sendSMSInput')
sms = sms_type(api_username="ken@hero.net", api_password=os.environ['SMS_SECRET'], did="+13103937981", dst="+15108127857", message=sms_body)
response_obj = client.service.sendSMS(sms)

items = response_obj['_value_1']

parsed_map = {}
for item in items:
    key_elem = item.find('key')
    val_elem = item.find('value')
    if key_elem is not None and val_elem is not None:
        key = key_elem.text
        val = val_elem.text
        parsed_map[key] = val

if parsed_map['status'] != 'success':
    raise RuntimeError(parsed_map)

