import csv
import os
from urllib.parse import urlparse, parse_qs

import requests

_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA_FILE = os.path.join(_ROOT, os.environ.get("DATA_CSV", "data.csv"))
IMAGES_DIR = os.path.join(_ROOT, "static", "images")
BASE_URL = os.environ.get("BASE_URL", "http://158.160.151.247").rstrip("/")

def extract_file_id(url):
    if "drive.google.com" not in url:
        return None
    
    parsed = urlparse(url)
    qs = parse_qs(parsed.query)
    if 'id' in qs:
        return qs['id'][0]
    
    parts = parsed.path.split('/')
    if 'd' in parts:
        idx = parts.index('d')
        if idx + 1 < len(parts):
            return parts[idx+1]
            
    return None

def download_file(file_id, dest_path):
    url = f"https://drive.google.com/uc?export=download&id={file_id}"
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(dest_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                if chunk:
                    f.write(chunk)
        return True
    except Exception as e:
        print(f"Error downloading {file_id}: {e}")
        return False

def main():
    if not os.path.exists(IMAGES_DIR):
        os.makedirs(IMAGES_DIR)
        
    updates = []
    
    with open(DATA_FILE, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        
        mc_id = 1
        for row in reader:
            if not row: continue
            
            image_urls_str = row[8]
            if not image_urls_str:
                mc_id += 1
                continue
                
            first_url = image_urls_str.split(',')[0].strip()
            file_id = extract_file_id(first_url)
            
            if file_id:
                filename = f"mc_{mc_id}.jpg"
                dest_path = os.path.join(IMAGES_DIR, filename)
                
                print(f"Downloading image for MC {mc_id} (ID: {file_id})...")
                if download_file(file_id, dest_path):
                    new_url = f"{BASE_URL}/static/images/{filename}"
                    updates.append((new_url, mc_id))
                else:
                    print("Skipped.")
            else:
                print(f"Could not extract ID from {first_url}")
                
            mc_id += 1
            
    _sql_path = os.path.join(_ROOT, "scripts", "update_images.sql")
    with open(_sql_path, "w", encoding="utf-8") as f:
        for url, mid in updates:
            f.write(f"UPDATE masterclasses SET image_url = '{url}' WHERE id = {mid};\n")
            
    print(f"Generated {_sql_path} with {len(updates)} updates.")

if __name__ == "__main__":
    main()

