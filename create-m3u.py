#!/usr/bin/env python3
import json
import os
import sys
from pathlib import Path
NOW = sys.argv[1]
BASE_URL = os.environ['BASE']
USERNAME = os.environ['USER']
PASSWORD = os.environ['PASS']
CHANNELS_FILE = Path(f"channels.{NOW}.json")
CATEGORIES_FILE = Path(f"categories.{NOW}.json")
OUTPUT_FILE = Path(f"eagle.{NOW}.m3u")

channels = json.loads(CHANNELS_FILE.read_text())
categories = json.loads(CATEGORIES_FILE.read_text())

cat_map = {c["category_id"]: c.get("category_name", "Unknown") for c in categories}

ignore_groups = [ f"|{g}|" for g in ["AR", "AF", "BE"] ]

with OUTPUT_FILE.open("w", encoding="utf-8") as f:
    f.write("#EXTM3U\n")
    for ch in channels:
        name = ch.get("name", "")
        epg_id = ch.get("epg_channel_id", "")
        logo = ch.get("stream_icon", "")
        stream_id = ch.get("stream_id")
        cat_id = ch.get("category_id")
        group = cat_map.get(str(cat_id), "Unknown")
        url = f"{BASE_URL}/{USERNAME}/{PASSWORD}/{stream_id}"

        if group[0:4] in ignore_groups:
            continue

        f.write(
            f'#EXTINF:-1 tvg-ID="{epg_id}" tvg-name="{name}" '
            f'tvg-logo="{logo}" group-title="{group}",{name}\n'
            f'{url}\n'
        )

print(f"Wrote {OUTPUT_FILE} with {len(channels)} entries")
