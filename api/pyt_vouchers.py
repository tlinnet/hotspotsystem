import requests

# The API key
key = "xx"

# The location ID
id = "4"


# Assign key
headers = {'sn-apikey': key}
# Root access
root1 = 'https://api.hotspotsystem.com/v1.0'
# limit
limit = 100
# Offset
offset = 0
# sort
#sort = "voucher_code"
sort = None

def api_locations_locationId_vouchers_v1(root=None, headers=None, id=None, limit=None, offset=None, sort=None):
    url = root + '/locations/' + id + '/vouchers.json'
    params = {'limit': limit, 'offset': offset, 'sort': sort}
    r = requests.get(url, auth=(headers['sn-apikey'], 'x'), params=params)
    #print r.json()
    for v in r.json()['results']:
        #print "C: %11s, V:% 5s m/H, P: %4s, T: %4s" % (v['voucher_code'], v['validity'], v['price_enduser'], v['usage_exp'])
        ctime = v['voucher_code'].split("-")[0]
        if "p" in ctime:
            continue
        print "%11s, T: %4s" % (v['voucher_code'], v['usage_exp'])

api_locations_locationId_vouchers_v1(root=root1, headers=headers, id=id, limit=limit, offset=offset, sort=sort)