#!/usr/bin/env python

from optparse import OptionParser
import requests

# See options at: http://www.hotspotsystem.com/apidocs/api/reference/
# And at: http://www.hotspotsystem.com/apidocs-v1/

def main():
    parser = OptionParser(usage="usage: %prog [options] filename", version="%prog 1.0")
    parser.add_option("-k", "--key",
                      action="store",
                      dest="key",
                      default=None,
                      help="The API key")
    parser.add_option("--me",
                      action="store_true",
                      dest="me_flag",
                      default=False,
                      help="Use the GET /me API")
    parser.add_option("-l", "--locations",
                      action="store_true",
                      dest="locations_flag",
                      default=False,
                      help="Use the GET /locations API")
    parser.add_option("-i", "--id",
                      action="store",
                      dest="id",
                      default=None,
                      help="The API key")
    parser.add_option("-v", "--vouchers",
                      action="store_true",
                      dest="vouchers_flag",
                      default=False,
                      help="Use the GET /vouchers or GET /locations/{locationId}/vouchers API")

    (options, args) = parser.parse_args()

    if options.key == None:
        parser.error("Please supply the API key with -k option.")

    # Root access
    root1 = 'https://api.hotspotsystem.com/v1.0'
    root2 = 'https://api.hotspotsystem.com/v2.0'
    headers = {'sn-apikey': options.key}

    # Try the flag options
    if options.me_flag:
        api_me(root=root2, headers=headers)

    if options.locations_flag:
        api_locations_options(root=root2, headers=headers)
        api_locations(root=root2, headers=headers)

    if options.vouchers_flag:
        if options.id == None:
            api_vouchers(root=root2, headers=headers)
        else:
            api_locations_locationId_vouchersv1(root=root1, headers=headers, id=options.id)
            #api_locations_locationId_vouchersv2(root=root2, headers=headers, id=options.id)


def api_me(root=None, headers=None):
    print("Use the GET /me API")
    url = root + '/me'
    r = requests.get(url, headers=headers)
    #print("Status code is: %s")%(r.status_code)    
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    print r.json()


def api_locations_options(root=None, headers=None):
    print("Use the GET /locations/options API")
    url = root + '/locations/options'
    r = requests.get(url, headers=headers)
    #print("Status code is: %s")%(r.status_code)    
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    print r.json()


def api_locations(root=None, headers=None):
    print("Use the GET /locations API")
    url = root + '/locations'
    r = requests.get(url, headers=headers)
    #print("Status code is: %s")%(r.status_code)    
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    print r.json()
    #print r.json()['items'][1]


def api_vouchers(root=None, headers=None):
    print("Use the GET /vouchers API")
    url = root + '/vouchers'
    r = requests.get(url, headers=headers)
    #print("Status code is: %s")%(r.status_code)    
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    for v in r.json()['items']:
        print v


def api_locations_locationId_vouchersv1(root=None, headers=None, id=None):
    print("GET /locations/{locationId}/vouchers for id:%s"%id)
    url = root + '/locations/' + id + '/vouchers.json'
    print url
    r = requests.get(url, auth=(headers['sn-apikey'], 'x'))
    #print("Status code is: %s")%(r.status_code)    
    #print("The headers are:")
    #print r.headers
    #print("The content for json is:")
    print r.json().keys()
    print r.json()['metadata']
    #print r.json()
    #for v in r.json()['results']:
    #    print v


def api_locations_locationId_vouchersv2(root=None, headers=None, id=None):
    print("GET /locations/{locationId}/vouchers for id:%s"%id)
    url = root + '/locations/' + id + '/vouchers'
    print url
    params = {'locationId': id}
    r = requests.get(url, headers=headers, params=params)
    #print("Status code is: %s")%(r.status_code)    
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    print r.json().keys()
    print r.json()['metadata']
    #for v in r.json()['items']:
    #    print v






if __name__ == '__main__':
    main()