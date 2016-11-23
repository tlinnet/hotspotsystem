import requests

key = "x"

i="4"
h={'sn-apikey': key}
root='https://api.hotspotsystem.com/v1.0'
pac=7

url=root+'/locations/'+i+'/generate/voucher.json'
p = {'package': pac}
r = requests.get(url, auth=(h['sn-apikey'], 'x'), params=p)
print r.json()['access_code']