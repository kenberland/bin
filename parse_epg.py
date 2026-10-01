#!/usr/bin/env python3
"""Parse eagle.xml, keep only US and FR channels/programmes, print stats."""

import argparse
import xml.etree.ElementTree as ET
from collections import Counter
from pathlib import Path
import re

parser = argparse.ArgumentParser(description="Filter XMLTV by country codes.")
parser.add_argument("--in", dest="input", default="eagle.xml", help="Input XMLTV file")
parser.add_argument("--out", dest="output", default="eagle-trimmed.xml", help="Output XMLTV file")
parser.add_argument("--langs", default="US,FR", help="Comma-separated country codes to keep")
args = parser.parse_args()

INPUT = Path(args.input)
OUTPUT = Path(args.output)
KEEP_COUNTRIES = set(args.langs.split(","))

# --- Pass 1: Find which channel IDs belong to US/FR ---

print(f"Parsing {INPUT} ({INPUT.stat().st_size / 1e6:.1f} MB)...")

keep_channel_ids = set()
country_counter = Counter()
total_channels = 0

for event, elem in ET.iterparse(INPUT, events=("end",)):
    if elem.tag == "channel":
        total_channels += 1
        display = elem.findtext("display-name", "")
        m = re.match(r"\|([A-Z]{2})\|", display)
        country = m.group(1) if m else "??"
        country_counter[country] += 1
        if country in KEEP_COUNTRIES:
            keep_channel_ids.add(elem.get("id", ""))
        elem.clear()
    elif elem.tag == "programme":
        elem.clear()

print(f"\nTotal channels: {total_channels}")
print("Channels by country:")
for code, count in country_counter.most_common():
    marker = " <-- KEEP" if code in KEEP_COUNTRIES else ""
    print(f"  {code}: {count}{marker}")
print(f"\nKeeping {len(keep_channel_ids)} unique channel IDs for {KEEP_COUNTRIES}")

# --- Pass 2: Write filtered file ---

print(f"\nWriting {OUTPUT}...")

kept_channels = 0
kept_programmes = 0
dropped_programmes = 0

out = open(OUTPUT, "w", encoding="utf-8")
out.write('<?xml version="1.0" encoding="utf-8" ?>\n')
out.write('<!DOCTYPE tv SYSTEM "xmltv.dtd">\n')
out.write('<tv generator-info-name="trimmed">\n')

for event, elem in ET.iterparse(INPUT, events=("end",)):
    if elem.tag == "channel":
        if elem.get("id", "") in keep_channel_ids:
            out.write(ET.tostring(elem, encoding="unicode"))
            out.write("\n")
            kept_channels += 1
        elem.clear()

    elif elem.tag == "programme":
        if elem.get("channel", "") in keep_channel_ids:
            out.write(ET.tostring(elem, encoding="unicode"))
            out.write("\n")
            kept_programmes += 1
        else:
            dropped_programmes += 1
        elem.clear()

out.write("</tv>\n")
out.close()

trimmed_size = OUTPUT.stat().st_size / 1e6
original_size = INPUT.stat().st_size / 1e6
print(f"\nKept {kept_channels} channels, {kept_programmes} programmes")
print(f"Dropped {dropped_programmes} programmes")
print(f"Original: {original_size:.1f} MB -> Trimmed: {trimmed_size:.1f} MB ({trimmed_size/original_size*100:.0f}%)")
