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
# https://github.com/tlinnet/hotspotsystem/tree/master/api                    #
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

import platform
import logging
import sys, os, json
import requests
from time import strftime

##########################################

# custom logging level
FINE = 15

# Silence request
logging.getLogger("requests").setLevel(logging.WARNING)
logging.getLogger("urllib3").setLevel(logging.WARNING)

# file locations used by the program
PYTHONISTA_DOC_DIR = os.path.expanduser('~/Documents')
SYNC_FOLDER_NAME = '.hotspotsystem'
SYNC_STATE_FOLDER = os.path.join(PYTHONISTA_DOC_DIR, SYNC_FOLDER_NAME)
CONFIG_FILENAME = 'hotspotsystem.conf'
CONFIG_FILEPATH = os.path.join(SYNC_STATE_FOLDER, CONFIG_FILENAME)

##########################################

# Check if pythonista
ispythonista = False

if platform.system() == 'Darwin':
    if platform.machine().startswith('iP'):
        print('You are running on iOS!')
        ispythonista = True
    else:
        print('You are running on Mac OS X!')
else:
    print('Please upgrade to a real computer and then press any key to continue...')

# Import pythonista specific modules
if ispythonista:
    import console

# Python 3 compatibility
try: 
	input = raw_input
except NameError:
	pass

def main():
    # Process any supplied arguments
    log_level = 'INFO'
    update_config = False
    
    for argument in sys.argv:
        if argument.lower() == '-v':
            log_level = 'FINE'
        elif argument.lower() == '-vv':
            log_level = 'DEBUG'
        elif argument.lower() == '-c':
            update_config = True
            
    # configure logging
    log_format = "%(message)s"
    
    logging.addLevelName(FINE, 'FINE')
    for handler in logging.getLogger().handlers:
        logging.getLogger().removeHandler(handler)
    logging.basicConfig(format=log_format, level=log_level)

    # disable dimming the screen
    if ispythonista:
        console.set_idle_timer_disabled(True)

    # Load the initial configuration
    config = setup_configuration()

    ans=True
    while ans:
        print ("""
 1. Show available vouchers
 2. Show last generated voucher
 3. Generate a voucher

 4. Change settings
 5. Exit/Quit
        """)
        ans=raw_input("What would you like to do? ") 
        if ans=="1": 
            print("")
            print("------------------------------------------")
            print("")
            print(" Vouchers - not activated yet            :")
            print("------------------------------------------")
            print_vouchers(config=config)

        elif ans=="2": 
            print("")
            print("------------------------------------------")
            print("")
            print(" Show last generated voucher             :")
            print("------------------------------------------")
            print_last_voucher(config=config)

        elif ans=="3":
            print("")
            print("------------------------------------------")
            print("")
            print(" Generating a voucher                    :")
            print("------------------------------------------")
            generate_voucher(config=config)

        elif ans=="4":
            print("")
            print("------------------------------------------")
            print("")
            print(" Changing settings                       :")
            print("------------------------------------------")
            config=change_settings(config=config)

        elif ans=="5":
            print("\n Goodbye")
            ans=False

        elif ans !="":
            print("\n Not Valid Choice Try again")

    # re-enable dimming the screen
    if ispythonista:
        console.set_idle_timer_disabled(False)

# Load the configuration file, if it exists. 
# if a configuration file does not exist this will prompt
# the user for inital configuration values		
def setup_configuration():
    if not os.path.exists(SYNC_STATE_FOLDER):
        os.mkdir(SYNC_STATE_FOLDER)
    if os.path.exists(CONFIG_FILEPATH):
        with open(CONFIG_FILEPATH, 'r') as config_file:
            config = json.load(config_file)
    else:
        logging.log(FINE, 'Configuration file missing')
        config = {}
        logging.info('Get your API key and secret from the hotspotsystem website')
        config['API_KEY'] = input('''Enter your API key:\n''').strip()
        config['LOC_ID'] = input('''Enter the location id [Loc. ID]:\n''').strip()
        config['limit'] = 100
        config['offset'] = 0
        config['package'] = 7
        config['last_voucher'] = ""
        config['last_voucher_time'] = ""
        # Write the config file back
        write_configuration(config)
    return config

# Write the updated configuration
def write_configuration(config):
	with open(CONFIG_FILEPATH, 'w') as config_file:
			json.dump(config, config_file, indent=1)

# Change settings
def change_settings(config=None):
    ans=True
    while ans:
        print ("""
 1. Change default limit of shown vouchers
 2. Change offset
 3. Change voucher package id
 4. Reset configuration file. 
 NOTE: This will delete the API key and location id.

 5. Exit menu
        """)
        ans=raw_input("What would you like to do? ") 
        if ans=="1": 
            print("Current limit of shown vouchers: %s"%config['limit'])
            config['limit'] = input('''Enter new limit of shown vouchers:\n''').strip() or "100"
            if not config['limit'].isdigit():
                config['limit'] = "100"
            print("New limit of shown vouchers: %s"%config['limit'])
            write_configuration(config)

        elif ans=="2":
            print("Current offset of shown vouchers: %s"%config['offset'])
            config['offset'] = input('''Enter new offset of shown vouchers:\n''').strip() or "0"
            if not config['offset'].isdigit():
                config['offset'] = "0"
            print("New offset of shown vouchers: %s"%config['offset'])
            write_configuration(config)

        elif ans=="3":
            print("Current voucher package id: %s"%config['package'])
            config['package'] = input('''Enter new voucher package id:\n''').strip() or "7"
            if not config['package'].isdigit():
                config['package'] = "7"
            print("New voucher package id: %s"%config['package'])
            write_configuration(config)

        elif ans=="4":
            print("Resetting configuration file.")
            os.remove(CONFIG_FILEPATH)
            setup_configuration()

        elif ans=="5":
            ans=False

        elif ans !="":
            print("\n Not Valid Choice Try again")


# See API options at: 
# http://www.hotspotsystem.com/apidocs-v1
# http://www.hotspotsystem.com/apidocs/api/reference

# Print Vouchers
def print_vouchers(config=None):
    root='https://api.hotspotsystem.com/v1.0'
    url=root+'/locations/'+config['LOC_ID']+'/vouchers.json'
    params = {'limit':config['limit'],'offset':config['offset']}
    r = requests.get(url, auth=(config['API_KEY'], 'x'), params=params)
    #cur_time = strftime("%Y-%m-%d %H:%M:%S")
    #print("Current time is: %s"%cur_time)
    # print results
    voucher_codes = []
    for v in r.json()['results']:
        ct = v['voucher_code'].split("-")[0]
        if "p" in ct:
            continue
        print "%11s" % (v['voucher_code'])
        voucher_codes.append(v['voucher_code'])

    return voucher_codes


def print_last_voucher(config=None):
    # print results
    print("")
    print("You have to activate the card before first use.")
    print("After activation the same code can be used as the")
    print("Username and Password to log in to the Hotspot.")
    print("")
    print("Last voucher generated:")
    print("-----------------------")
    print("| %s |"%config['last_voucher_time'])
    print("|     %11s     |"%config['last_voucher'])
    print("-----------------------")


def generate_voucher(config=None):
    root='https://api.hotspotsystem.com/v1.0'
    url=root+'/locations/'+config['LOC_ID']+'/generate/voucher.json'
    params = {'package':config['package']}
    r = requests.get(url, auth=(config['API_KEY'], 'x'), params=params)
    # Get the time
    cur_time = strftime("%Y-%m-%d %H:%M:%S")

    config['last_voucher'] = r.json()['access_code']
    config['last_voucher_time'] = cur_time
    write_configuration(config)
    # print results
    print("")
    print("You have to activate the card before first use.")
    print("After activation the same code can be used as the")
    print("Username and Password to log in to the Hotspot.")
    print("")
    print("-----------------------")
    print("| %s |"%cur_time)
    print("|     %11s     |"%r.json()['access_code'])
    print("-----------------------")

    return r.json()['access_code']


if __name__ == "__main__":
    main()
    logging.info('Hotspotsystem done!')
    
