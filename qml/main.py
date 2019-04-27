""" Manipulate marker images to display the cost as well """

import io
import os
import sys

RQSTS = True
NOOS = False

try:
    import requests
except ImportError as err:
    print(err)
    RQSTS = False

try:
    sys.path.append('../PIL/')
    from PIL import Image, ImageDraw, ImageFont
except ImportError as err:
    print(err)
    NOOS = True

try:
    import pyotherside
except ImportError as err:
    print(err)
    NOOS = True

APP_ID = os.environ.get("APP_ID", "").split('_')[0]
CONFIGBASE = os.environ.get("XDG_CONFIG_HOME", "/tmp") + "/" + APP_ID

HEADERS = {}
HEADERS['User-Agent'] = "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 "
HEADERS['User-Agent'] += "(KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"

def load_data(image_id, requested_size):
    """ Manipulate marker images to display the cost as well """

    if requested_size != "":
        pass

    brand, cost, colour, fontsize = image_id.split('%7C')
    marker = "assets/" + brand + ".png"
    bg_img = Image.new("RGBA", (65, 90), (255, 0, 0, 0))
    marker = Image.open(marker).convert("RGBA")
    bg_img.paste(marker, (0, 31), marker)

    draw = ImageDraw.Draw(bg_img)
    if colour == "blue":
        draw.rectangle(((0, 0), (65, 31)), fill=(0, 70, 126))
    else:
        draw.rectangle(((0, 0), (65, 31)), fill=(202, 30, 46))

    font = ImageFont.FreeTypeFont("/usr/share/fonts/truetype/ubuntu-font-family/Ubuntu-R.ttf", \
                                  size=int(fontsize))

    if "." not in cost:
        cost += ".0"

    draw.text((4, 4), cost, font=font)

    binimg = io.BytesIO()
    bg_img.save(binimg, 'png')
    return bytearray(binimg.getvalue()), (-1, -1), pyotherside.format_data

if not NOOS:
    pyotherside.set_image_provider(load_data)

def get_noos():
    """ Let the app know if image library is installed or not... """

    cfg = get_config()

    if cfg is not None:
        lat, lon, zoom, fueltype, gps_lock = cfg
        return NOOS, RQSTS, lat, lon, zoom, fueltype, gps_lock

    return NOOS, RQSTS, "", "", "", "", ""

def download_json(trlat, bllon, bllat, trlon, fueltype):
    """ Download json string from server based on a bounding box """

    trlat = str(trlat)
    bllon = str(bllon)
    bllat = str(bllat)
    trlon = str(trlon)

    session = requests.Session()
    session.headers = HEADERS
    url = "https://api.onegov.nsw.gov.au/FuelCheckApp/v1/fuel/prices/" + \
          "bylocation?bottomLeftLatitude=" + bllat + "&bottomLeftLongitude=" + bllon + \
          "&topRightLatitude=" + trlat + "&topRightLongitude=" + trlon + \
          "&fueltype=" + fueltype + "&brands=SelectAll"
    ret = session.get(url).text.strip()
    return ret

def check_paths():
    """ check and make directories as needed. """

    os.makedirs(CONFIGBASE, exist_ok=True)

def read_file(filename):
    """ Read content from a file """

    check_paths()

    try:
        filename = CONFIGBASE + "/" + filename
        my_file = open(filename, "r+")
        ret = my_file.read()
        my_file.close()
        return ret
    except Exception as error:
        # print("line 107")
        # print(error)
        pass

    return None

def get_config():
    """ open and parse the config file """

    data = read_file("fuelcheck.ini")
    if data is None:
        return "-33.86", "151.20", "18", "U91", "0"

    for line in data.split("\n"):
        if line.split("=", 1)[0] == "lat":
            lat = line.split("=", 1)[1]
        if line.split("=", 1)[0] == "lon":
            lon = line.split("=", 1)[1]
        if line.split("=", 1)[0] == "zoom":
            zoom = line.split("=", 1)[1]
        if line.split("=", 1)[0] == "fueltype":
            fueltype = line.split("=", 1)[1]
        if line.split("=", 1)[0] == "gps_lock":
            gps_lock = line.split("=", 1)[1]

    return [lat, lon, zoom, fueltype, gps_lock]

def write_file(filename, mydata):
    """ save data to a file """

    check_paths()
    filename = CONFIGBASE + "/" + filename
    my_file = open(filename, "w")
    my_file.write(str(mydata))
    my_file.close()
    print("Wrote to: " + filename)
    return CONFIGBASE

def save_config(lat, lon, zoom, fueltype, gps_lock):
    """ Save config variables to ini file """

    mystr = "lat=" + str(lat) + "\nlon=" + str(lon) + "\nzoom=" + str(zoom) + \
            "\nfueltype=" + fueltype + "\ngps_lock=" + str(gps_lock)

    print(mystr)

    write_file("fuelcheck.ini", mystr)
