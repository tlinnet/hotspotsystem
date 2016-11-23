import requests

# The API key
key = "fc8962e6f903acf14e3736f95a160b9f"

# The location ID
id = "4"


# Assign key
headers = {'sn-apikey': key}
# Root access
root1 = 'https://api.hotspotsystem.com/v1.0'
# Offset
offset = 0
# limit
limit = 100

def api_locations_locationId_vouchers_v1(root=None, headers=None, id=None, offset=None, limit=None):
    url = root + '/locations/' + id + '/vouchers.json'
    params = {'offset': offset, 'limit': limit}
    r = requests.get(url, auth=(headers['sn-apikey'], 'x'), params=params)
    for v in r.json()['results']:
        print "C: %11s, V:% 5s m/H, P: %4s, T: %4s" % (v['voucher_code'], v['validity'], v['price_enduser'], v['usage_exp'])

api_locations_locationId_vouchers_v1(root=root1, headers=headers, id=id, offset=offset, limit=limit)