import csv
import os
import re
from datetime import datetime

import requests

_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
_CSV = os.environ.get("CSV_PATH", os.path.join(_ROOT, "data.csv"))
_API_BASE = os.environ.get("API_BASE_URL", "http://127.0.0.1:80").rstrip("/")
API_URL = f"{_API_BASE}/mcadd"

def parse_price(price_str):
    if not price_str:
        return 0.0
    nums = re.findall(r'\d+', price_str.replace('\xa0', '').replace(' ', ''))
    if nums:
        return float(nums[0])
    return 0.0

def parse_date(date_str):
    try:
        dt = datetime.strptime(date_str, "%d.%m.%Y")
        return dt.strftime("%Y-%m-%d")
    except:
        return "1970-01-01"

def import_data(csv_file):
    with open(csv_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        count = 1
        for row in reader:
            if not row: continue
            
            try:
                title = row[1]
                description = row[2]
                price = parse_price(row[3])
                event_date = parse_date(row[4])
                category = row[5]
                duration = row[6]
                audience = row[7]
                image_url = row[8].split(',')[0].strip() if row[8] else "https://via.placeholder.com/150"
                additional_tags = row[9]
                organizer = row[10]
                website_raw = row[11].strip() if len(row) > 11 else ""
                if website_raw and not website_raw.startswith(("http://", "https://")):
                    website_raw = "https://" + website_raw
                website = website_raw
                contact_tg = row[12] if len(row) > 12 else ""
                contact_vk = row[13] if len(row) > 13 else ""
                contact_phone = row[14] if len(row) > 14 else ""

                payload = {
                    "id": count,
                    "title": title,
                    "description": description,
                    "price": price,
                    "event_date": event_date,
                    "category": category,
                    "duration": duration,
                    "audience": audience,
                    "image_url": image_url,
                    "additional_tags": additional_tags,
                    "organizer": organizer,
                    "website": website,
                    "contact_tg": contact_tg,
                    "contact_vk": contact_vk,
                    "contact_phone": contact_phone,
                    "location": organizer if organizer else "Moscow",
                    "format": "offline",
                    "company": "single",
                    "min_age": 0,
                    "rating": 5.0
                }

                print(f"Importing {title}...")
                resp = requests.post(API_URL, json=payload)
                if resp.status_code != 201:
                    print(f"Failed to import {title}: {resp.status_code} {resp.text}")
                
                count += 1
            except Exception as e:
                print(f"Error processing row: {e}")

if __name__ == "__main__":
    import_data(_CSV)

