from playwright.sync_api import sync_playwright, Page
import re
import logging
from datetime import datetime, timedelta
import pandas as pd
import os

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)
logger.disabled = False

def write_csv(data_list: list):
    df = pd.DataFrame(data_list)
    file_exists = os.path.exists("panchanga.csv")
    df.to_csv("panchanga.csv", mode='a', index=False, header=not file_exists)

def extract_panchanga(page: Page, date: str):
    # 1. date
    # date_locator = page.locator(".date")
    # logger.info(f"date: {date_locator.inner_text()}")
    logger.info(f"date: {date}")
    # 2. sams
    sams_locator = page.locator(".sams")
    # logger.info(f"sams: {sams_locator.inner_text()}")
    samvastara, aayana, rutu, masa, paksha = [x.strip() for x in sams_locator.inner_text().split(",")]
    rutu = rutu.replace(" rutu", "")
    masa = masa.replace(" masa", "")
    paksha = paksha.replace(" paksha", "")
    logger.info(f"samvastara: {samvastara}")
    logger.info(f"aayana: {aayana}")
    logger.info(f"rutu: {rutu}")
    logger.info(f"masa: {masa}")
    logger.info(f"paksha: {paksha}")
    # 3. tithi
    tithi_locator = page.locator(".thithi")
    tithi = tithi_locator.inner_text().split(",")[0].strip()
    tithi = tithi.replace(" Tithi", "")
    logger.info(f"tithi: {tithi}")
    # 4. dys
    dys_locator = page.locator(".dys")
    dys_re = re.sub(r'<br\s*[^>]*>', '\n', dys_locator.inner_html(), flags=re.IGNORECASE)
    dys_list = [itr.strip() for itr in dys_re.split("\n") if itr.strip()]
    # logger.info(f"dys: {dys_list}")
    vasara, nakshatra, yoga, karana = dys_list
    nakshatra = nakshatra.replace(" nakshatra", "")
    yoga = yoga.replace(" yoga", "")
    karana = karana.replace(" karna", "")
    logger.info(f"vasara: {vasara}")
    logger.info(f"nakshatra: {nakshatra}")
    logger.info(f"yoga: {yoga}")
    logger.info(f"karana: {karana}")
    suns_locator = page.locator(".suns").first
    suns_text = suns_locator.inner_text()
    # Extract sunrise and sunset using regex
    sunrise_match = re.search(r'Sunrise\s*(.+?)\s*Sunset', suns_text)
    sunset_match = re.search(r'Sunset\s*(.+?)(?:\s*Shraadha|$)', suns_text)
    sunrise = sunrise_match.group(1).strip() if sunrise_match else ""
    sunset = sunset_match.group(1).strip() if sunset_match else ""
    logger.info(f"sunrise: {sunrise}")
    logger.info(f"sunset: {sunset}")
    write_csv([{
        "date": date, "samvastara": samvastara, "aayana": aayana, "rutu": rutu, "masa": masa, 
        "paksha": paksha, "tithi": tithi, "vasara": vasara, "nakshatra": nakshatra, "yoga": yoga, 
        "karana": karana, sunrise: sunrise, "sunset": sunset}])

def date_changer(page: Page, new_date: str):
    # get the date locator
    date_locator = page.locator(".mydate")
    date_locator.wait_for()
    # fill the date locator
    date_locator.fill(new_date)
    
def get_next_day(current_date: str) -> str:
    current_date_obj = datetime.strptime(current_date, "%Y-%m-%d").date()
    next_date_obj = current_date_obj + timedelta(days=1)
    return next_date_obj.strftime("%Y-%m-%d")

with sync_playwright() as p:
    # launch the browser
    browser = p.chromium.launch(headless=True, slow_mo=50)
    page = browser.new_page()
    page.goto("https://srsmatha.org/srsbook/?page=app/app&appcontent=app_panchanga")
    date = "2026-01-01"
    while date != "2026-03-20":
        # extract the panchanga
        extract_panchanga(page, date)
        # get the next day
        date = get_next_day(date)
        # set the date
        date_changer(page, date)
    browser.close()
    p.stop()