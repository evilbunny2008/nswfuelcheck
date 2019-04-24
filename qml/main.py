""" Manipulate marker images to display the cost as well """

import io

rqsts = True
NOOS = False

try:
    import requests
except ImportError as err:
    print(err)
    rqsts = False

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as err:
    print(err)
    NOOS = True

try:
    import pyotherside
except ImportError as err:
    print(err)
    NOOS = True

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

def get_noos():
    """ Let the app know if image library is installed or not... """
    return NOOS, rqsts

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

if not NOOS:
    pyotherside.set_image_provider(load_data)
