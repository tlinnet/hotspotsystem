#!/usr/bin/env python

from optparse import OptionParser
import requests

###############################################################################
#                                                                             #
#                           Hotspotsystem Vouchers                            #
#                                                                             #
#               View current free vouchers and create new vouchers            #
#                                                                             #
#                             by Troels Schwarz-Linnet                        #
#                                                                             #
###############################################################################
#                                                                             #
#                                   Licence                                   #
#                                                                             #
# Copyright (C) 2016  Troels Schwarz-Linnet, Denmark                          #
#                                                                             #
# Contact: tlinnet *at* gmail dot com                                         #
#                                                                             #
# Available at:                                                               #
# https://github.com/tlinnet/hotspotsystem/tree/master/api/pythonista         #
#                                                                             #
#                                                                             #
# This program is free software; you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU Library General Public License for more details.                        #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with this program; if not, write to the Free Software                 #
#                                                                             #
###############################################################################

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
    parser.add_option("-g", "--generate",
                      action="store_true",
                      dest="generate_flag",
                      default=False,
                      help="Use the GET /locations/{locationId}/generate/voucher API")

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
            api_locations_locationId_vouchers_v1(root=root1, headers=headers, id=options.id)
            #api_locations_locationId_vouchers_v2(root=root2, headers=headers, id=options.id)

    if options.generate_flag:
        if options.id == None:
            parser.error("Please supply the location ID where the voucher credit will be deducted from with -i option.")
        else:
            api_locations_locationId_generate_voucher_v1(root=root1, headers=headers, id=options.id)


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
    print r.json().keys()
    print r.json()['metadata']


def api_locations_locationId_vouchers_v1(root=None, headers=None, id=None):
    print("GET /locations/{locationId}/vouchers for id:%s"%id)
    url = root + '/locations/' + id + '/vouchers.json'
    print url
    r = requests.get(url, auth=(headers['sn-apikey'], 'x'))
    #print("Status code is: %s")%(r.status_code)
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    for v in r.json()['results']:
        # Possible keys
        # voucher_code, validity, price_enduser, usage_exp
        # serial, simultaneous_use,limit_dl, limit_ul, limit_tl
        print "Code: %11s, Validity:%8d min/H, price: %4s, Time left: %4s" % (v['voucher_code'], v['validity'], v['price_enduser'], v['usage_exp'])
    print r.json().keys()
    print r.json()['metadata']


def api_locations_locationId_vouchers_v2(root=None, headers=None, id=None):
    print("GET /locations/{locationId}/vouchers for id:%s"%id)
    url = root + '/locations/' + id + '/vouchers'
    print url
    params = {'locationId': id}
    r = requests.get(url, headers=headers, params=params)
    #print("Status code is: %s")%(r.status_code)
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    for v in r.json()['items']:
        print v
    print r.json().keys()
    print r.json()['metadata']


def api_locations_locationId_generate_voucher_v1(root=None, headers=None, id=None):
    print("GET /locations/{locationId}/generate/voucher for id:%s"%id)
    url = root + '/locations/' + id + '/generate/voucher.json'
    print url
    # package ID of a custom package which is used to define the voucher parameters.
    # If no package is specified, a voucher code will be generated based on the default free access of the location.
    params = {'package': 7}
    r = requests.get(url, auth=(headers['sn-apikey'], 'x'), params=params)
    print("Status code is: %s")%(r.status_code)
    #print("The headers are:")
    #print r.headers
    print("The content for json is:")
    print r.json().keys()
    print r.json()
    print r.json()['access_code']


if __name__ == '__main__':
    main()