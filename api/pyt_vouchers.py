import requests

key = "x"

i="4"
h={'sn-apikey': key}
root='https://api.hotspotsystem.com/v1.0'
l=100
o=0

url=root+'/locations/'+i+'/vouchers.json'
p = {'limit':l,'offset':o}
r = requests.get(url, auth=(h['sn-apikey'], 'x'), params=p)
for v in r.json()['results']:
    ct = v['voucher_code'].split("-")[0]
    if "p" in ct:
        continue
    print "%11s, T: %4s" % (v['voucher_code'], v['usage_exp'])