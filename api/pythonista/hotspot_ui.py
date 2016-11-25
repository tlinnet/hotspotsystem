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
#  Inspired by: https://github.com/khilnani/pythonista-scripts/blob/          #
#  master/thirdparty/UI/ui-tutorial/Three-Column-Sortable-TableView.py        #
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

import platform, os, datetime, logging, sys, os, json, requests
from operator import itemgetter
from time import strftime

# From: 
# https://github.com/khilnani/pythonista-scripts/blob/master/thirdparty/UI/ui-tutorial/Three-Column-Sortable-TableView.py
# http://omz-software.com/pythonista/docs/ios/ui.html
# http://omz-software.com/pythonista/docs/ios/console.html

# See hotspotsystem API options at: 
# http://www.hotspotsystem.com/apidocs-v1
# http://www.hotspotsystem.com/apidocs/api/reference

##########################################
# Custom logging level
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

# Check platform
if platform.system() == 'Darwin':
    if platform.machine().startswith('iP'):
        ispythonista = True
    else:
        print('You are running on Mac OS X! %s - %s'%(platform.system(), platform.machine()))
else:
    print('Please upgrade to a real computer and then press any key to continue...')

# Import pythonista specific modules
if ispythonista:
    import ui, console
    console.clear()
    # Disable dimming the screen
    console.set_idle_timer_disabled(True)

# Python 3 compatibility
try: 
	input = raw_input
except NameError:
	pass


# Define Class for shared functions
class Common(object):
    def __init__(self):
        self.setup_configuration()

    # If a configuration file does not exist, this will prompt the user for inital configuration values		
    def setup_configuration(self):
        if not os.path.exists(SYNC_STATE_FOLDER):
            os.mkdir(SYNC_STATE_FOLDER)
        if os.path.exists(CONFIG_FILEPATH):
            with open(CONFIG_FILEPATH, 'r') as config_file:
                config = json.load(config_file)
                config['reset'] = False
        else:
            logging.log(FINE, 'Configuration file missing')
            config = {}
            config['limit'] = "100"
            config['offset'] = "0"
            config['last_voucher'] = ""
            config['last_voucher_time'] = ""
            config['reset'] = True
            config['error_message'] = None
            config['success'] = None

        # Store
        self.config = config
        # Write the config file back
        self.write_configuration()

    # Read vouchers from config dict
    def read_vouchers(self):
        if 'stored_vouchers' in self.config:
            return self.config['stored_vouchers']
        else:
            self.get_vouchers()
            success = self.get_config(key='success')
            if success:
                return self.config['stored_vouchers']
            else:
                return []

    # Use hotspotsystem API to get all unused vouchers
    def get_vouchers(self):
        root='https://api.hotspotsystem.com/v1.0'
        url=root+'/locations/'+self.config['LOC_ID']+'/vouchers.json'
        params = {'limit':self.config['limit'],'offset':self.config['offset']}
        r = requests.get(url, auth=(self.config['API_KEY'], 'x'), params=params)
        vouchers = []
        i = 0

        # Get success
        success = r.json()['success']
        self.config['success'] = success
        if success:
            for v in r.json()['results']:
                ct = v['voucher_code'].split("-")[0]
                if "p" in ct:
                    continue
                vouchers.append(("%03d"%i, v['voucher_code'], v['usage_exp']))
                i += 1
            # Store and save
            self.config['stored_vouchers'] = vouchers
            self.config['error_message'] = None
            self.write_configuration()

        # If no success, store the error message
        else:
            self.config['error_message'] = r.json()['error']['message']
            self.write_configuration()

    # Read the last generated voucher from dict
    def read_last_voucher(self):
        if 'last_voucher' in self.config:
            return (self.config['last_voucher_time'], self.config['last_voucher'])
        else:
            return ("---", "---")

    # Use hotspotsystem API to generate voucher
    def generate_voucher(self):
        root='https://api.hotspotsystem.com/v1.0'
        url=root+'/locations/'+self.config['LOC_ID']+'/generate/voucher.json'
        params = {'package':self.config['package']}
        r = requests.get(url, auth=(self.config['API_KEY'], 'x'), params=params)

        # Get success
        success = r.json()['success']
        self.config['success'] = success
        if success:
            # Get the time
            cur_time = strftime("%Y-%m-%d %H:%M:%S")
            # Store and save
            self.config['last_voucher'] = r.json()['access_code']
            self.config['last_voucher_time'] = cur_time
            self.config['error_message'] = None
            self.write_configuration()

        # If no success, store the error message
        else:
            self.config['error_message'] = r.json()['error']['message']
            self.write_configuration()

    # Write the updated configuration
    def write_configuration(self):
	    with open(CONFIG_FILEPATH, 'w') as config_file:
			json.dump(self.config, config_file, indent=1)

    # Return the value of the config
    def get_config(self, key):
        return self.config[str(key)]

    # Write config
    def write_config(self, key, value):
        self.config[str(key)] = value
        self.write_configuration()


# Define the class for the pythonista UI
if ispythonista:
    class MyTableView(ui.View):
        def __init__(self):
            # Load the initial configuration
            self.c = Common()
            self.setup_configuration()

            #  Define buttons colors
            self.select_color = 'lightgrey'
            self.unselect_color = 'white'
            self.active_button = None
            self.button_height = 50

            # Set name of View
            self.name = 'Hotspotsystem Vouchers'
            self.background_color = 'white'
            #self.tv.delegate = MyTableViewDelegate()

            # Define buttons and create the sub_views
            self.btn_1 = self.make_buttons('Index', True) #Name
            self.btn_2 = self.make_buttons('Code', True) #Size
            self.btn_3 = self.make_buttons('Time left', True) #Date

            # Make bottom button
            self.btn_4 = self.make_buttons('Refresh table', False)
            self.btn_5 = self.make_buttons('Generate', False)
            self.btn_6 = self.make_buttons('Settings', False)

            # Create a tableview, with data
            self.tv = ui.TableView()
            self.tv.row_height = 30
            self.tv.data_source = MyTableViewDataSource(self.tv.row_height)

            # Update tableview data
            self.tv.data_source.items = sorted(self.c.read_vouchers(), key=itemgetter(0), reverse=True)

            # Do not allow selection on the TableView
            self.tv.allows_selection = False

            # Add the table
            self.add_subview(self.tv)

            # Create TextView 1 and 2
            self.txtv_1 = ui.TextView()
            self.txtv_1.alignment = ui.ALIGN_CENTER
            self.txtv_1.editable = False
            self.txtv_1.font = ("AmericanTypewriter-Bold", 12)

            self.txtv_2 = ui.TextView()
            self.txtv_2.alignment = ui.ALIGN_CENTER
            self.txtv_2.editable = False
            self.txtv_2.font = ("AmericanTypewriter-Bold", 16)

            self.refresh_last_voucher()

            # Add the TextView
            self.add_subview(self.txtv_1)
            self.add_subview(self.txtv_2)

            # Show
            self.present('full_screen')

        # Do setup of config dictionary
        def setup_configuration(self):
            if self.c.get_config(key='reset'):
                #logging.info('Get your API key from the hotspotsystem website')
                API_KEY = console.input_alert("API Key", "from hotspotsystem", "", "OK")
                self.c.write_config('API_KEY', API_KEY)

                LOC_ID = console.input_alert("Location id", "Location id nr [Loc. ID]", "1", "OK")
                if not LOC_ID.isdigit():
                    package = "1"
                self.c.write_config('LOC_ID', LOC_ID)

                package = console.input_alert("Voucher package", "voucher package id nr", "1", "OK")
                if not package.isdigit():
                    package = "1"
                self.c.write_config('package', package)

        def check_api_call(self):
            success = self.c.get_config(key='success')
            if success:
                pass
            else:
                console.hud_alert(self.c.get_config(key='error_message'), 'error')
            return success

        def make_buttons(self, name, top):
            button = ui.Button()
            button.name = name
            button.title = name
            button.border_color = 'blue'
            button.border_width = 1
            button.corner_radius = 3
            button.background_color = self.unselect_color

            # Create the action for the top buttons
            if top:
                button.action = self.top_btn_action
            else:
                button.action = self.bot_btn_action

            # Create the view for the button
            self.add_subview(button)
            return button

        # Create the sorting actions for the buttons
        def top_btn_action(self, sender):
            names = [self.btn_1.name, self.btn_2.name, self.btn_3.name]
            sender_index = names.index(sender.name)
            if sender.background_color == (1.0, 1.0, 1.0, 1.0):    #thrid click on the same column doesn't work if it's no hardcoded color
                if sender.background_color == self.unselect_color:
                    sender.background_color = self.select_color
                    self.all_items = sorted(self.c.read_vouchers(), key=itemgetter(sender_index))
                else:
                    sender.background_color = self.unselect_color
                    self.all_items = sorted(self.c.read_vouchers(), key=itemgetter(sender_index), reverse=True)
            else:
                if self.active_button == None:
                    self.active_button = sender.name

                if sender.name == self.btn_1.name:
                    self.btn_1.background_color = self.select_color
                    self.all_items = sorted(self.c.read_vouchers(), key=itemgetter(sender_index))
                else:
                    self.btn_1.background_color = self.unselect_color

                if sender.name == self.btn_2.name:
                    self.btn_2.background_color = self.select_color
                    self.all_items = sorted(self.c.read_vouchers(), key=itemgetter(sender_index))
                else:
                    self.btn_2.background_color = self.unselect_color

                if sender.name == self.btn_3.name:
                    self.btn_3.background_color = self.select_color
                    self.all_items = sorted(self.c.read_vouchers(), key=itemgetter(sender_index))
                else:
                    self.btn_3.background_color = self.unselect_color


            self.tv.data_source.items = self.all_items
            self.tv.reload()
            self.active_button = sender.name

        @ui.in_background
        def bot_btn_action(self, sender):
            # Refresh
            if sender.name == self.btn_4.name:
                self.refresh_last_voucher()
                self.refresh_table()

            # Generate
            elif sender.name == self.btn_5.name:
                self.c.generate_voucher()
                if self.check_api_call():
                    self.refresh_last_voucher()
                    self.refresh_table()

            # Settings
            elif sender.name == self.btn_6.name:
                alert_result = console.alert('Setings',"change:", button1='limit/offset', button2='voucher package', button3='Reset app!')
                #selected button is returned as an integer 

                ui.KEYBOARD_NUMBER_PAD
                # Change limit and offset
                if alert_result == 1:
                    limit = console.input_alert("Change limit", "limit voucher list", self.c.get_config('limit'), "OK")
                    if not limit.isdigit():
                        limit = "100"
                    self.c.write_config('limit', limit)

                    offset = console.input_alert("Change offset", "offset in voucher list", self.c.get_config('offset'), "OK")
                    if not offset.isdigit():
                        offset = "0"
                    self.c.write_config('offset', offset)

                # Change voucher package
                elif alert_result == 2:
                    package = console.input_alert("Voucher package", "voucher package id nr", self.c.get_config('package'), "OK")
                    if not package.isdigit():
                        package = "1"
                    self.c.write_config('package', package)

                # Reset app
                elif alert_result == 3:
                    if os.path.exists(CONFIG_FILEPATH):
                        os.remove(CONFIG_FILEPATH)
                    self.c.write_config('reset', True)
                    self.setup_configuration()

                # Printe to screen
                self.txtv_1.text = "Settings:\nlimit=%s\noffset=%s"%(self.c.get_config('limit'), self.c.get_config('offset'))
                self.txtv_2.text = "package=%s"%(self.c.get_config('package'))

        # Refresh the table from the server
        def refresh_table(self):
            # Get vouchers from server.
            self.c.get_vouchers()
            if self.check_api_call():
                # Update data
                self.tv.data_source.items = sorted(self.c.read_vouchers(), key=itemgetter(0), reverse=True)
                self.tv.reload()

        def refresh_last_voucher(self):
            time, code = self.c.read_last_voucher()
            self.txtv_1.text = "Last voucher:\n%s"%time
            self.txtv_2.text = "%s"%code

        # Define layout of views
        def layout(self):
            self.tv.reload()
            # Top buttons
            self.btn_1.frame =(0*self.width/3, 0, self.width/3, self.button_height)
            self.btn_2.frame =(1*self.width/3, 0, self.width/3, self.button_height)
            self.btn_3.frame =(2*self.width/3, 0, self.width/3, self.button_height)
            # Bottom buttons
            self.btn_4.frame =(0*self.width/3, self.height - self.button_height*2, self.width/3, self.button_height)
            self.btn_5.frame =(1*self.width/3, self.height - self.button_height*2, self.width/3, 2*self.button_height)
            self.btn_6.frame =(0*self.width/3, self.height - self.button_height*1, self.width/3, self.button_height)
            # TableView frame
            self.tv.frame = (0, self.button_height, self.width, self.height - self.button_height*3)
            # Text field frame
            self.txtv_1.frame = (2*self.width/3, self.height - self.button_height*2, 1*self.width/3, 1*self.button_height)
            self.txtv_2.frame = (2*self.width/3, self.height - self.button_height*1, 1*self.width/3, 1*self.button_height)


# Define the class for the Table Data
class MyTableViewDataSource(object):
    def __init__(self, row_height):
        self.row_height = row_height
        self.width = None

    def tableview_number_of_rows(self, tableview, section):
        return len(tableview.data_source.items)

    def tableview_cell_for_row(self, tableview, section, row):
        self.width, height = ui.get_screen_size()
        cell = ui.TableViewCell()
        cell.bounds = (0,0,self.width,self.row_height)
        for i in range(3):
            self.make_labels(cell, tableview.data_source.items[row][i], i)
        return cell

    def make_labels(self, cell, text, pos):
        label = ui.Label()
        label.border_color = 'lightgrey'
        label.border_width = 0.5
        if pos == 2:
            #label.text = str(datetime.datetime.fromtimestamp(text))
            label.text = str(text)
        else:
            label.text = str(text)
        label.frame = (pos*self.width/3,0,self.width/3,self.row_height)
        label.alignment = ui.ALIGN_CENTER
        cell.content_view.add_subview(label)

#class MyTableViewDelegate(object):
#    def tableview_did_select(self, tableview, section, row):
#        print 'select'
#    def tableview_did_deselect(self, tableview, section, row):
#        print 'deselect'


# Define the class for python Interpreter
class Interpreter(object):
    def __init__(self):
        # Load the initial configuration
        self.c = Common()
        self.setup_configuration()

    # Do setup of config dictionary
    def setup_configuration(self):
        if self.c.get_config(key='reset'):
            logging.info('Get your API key from hotspotsystem')
            API_KEY = input('''Enter your API key:\n''').strip()
            self.c.write_config('API_KEY', API_KEY)

            LOC_ID = input('''Enter the location id nr [Loc. ID]:\n''').strip()
            if not LOC_ID.isdigit():
                package = "1"
            self.c.write_config('LOC_ID', LOC_ID)

            package = input('''Enter the Voucher package id nr:\n''').strip()
            if not package.isdigit():
                package = "1"
            self.c.write_config('package', package)

    def check_api_call(self):
        success = self.c.get_config(key='success')
        if success:
            pass
        else:
            print("------------------------------------------")
            print("|    !!!!         ERROR         !!!!     |")
            print("|          %s        |"%self.c.get_config(key='error_message'))
            print("------------------------------------------")
        return success

        
    # Create initial menu for selection
    def menu(self):
        ans=True
        while ans:
            print(" 1. Show available vouchers")
            print(" 2. Refresh voucher list from server ")
            print(" 3. Generate a voucher")
            print("")
            print(" 4. Change settings")
            print(" 5. Exit/Quit")

            ans=raw_input("What would you like to do? ") 
            if ans=="1": 
                print("")
                print("------------------------------------------")
                print("|                                        |")
                print(" Vouchers - not activated yet            :")
                print("------------------------------------------")
                self.print_vouchers()

            elif ans=="2": 
                print("")
                print("------------------------------------------")
                print("|                                        |")
                print(" Refresh voucher list from server        :")
                print("------------------------------------------")
                self.c.get_vouchers()
                if self.check_api_call():
                    self.print_vouchers()

            elif ans=="3":
                print("")
                print("------------------------------------------")
                print("")
                print(" Generating a voucher                    :")
                print("------------------------------------------")
                self.c.generate_voucher()
                if self.check_api_call():
                    self.print_generated_voucher()

            elif ans=="4":
                print("")
                print("------------------------------------------")
                print("")
                print(" Changing settings                       :")
                print("------------------------------------------")
                self.change_settings()

            elif ans=="5":
                print("\n Goodbye")
                ans=False

            elif ans !="" or ans =="":
                print("\n-Not Valid Choice - Try again-\n")
                ans=True

    # Change settings
    def change_settings(self):
        ans=True
        while ans:
            print(" 1. Change default limit of shown vouchers")
            print(" 2. Change offset")
            print(" 3. Change voucher package id")
            print(" 4. Reset configuration file. ")
            print(" NOTE: This will delete the API key and location id.")
            print("")
            print(" 5. Exit menu")

            ans=raw_input("What would you like to do? ") 
            if ans=="1": 
                print("Current limit of shown vouchers: %s"%self.c.get_config('limit'))
                limit = input('''Enter new limit of shown vouchers:\n''').strip() or "100"
                if not limit.isdigit():
                    limit = "100"
                print("New limit of shown vouchers: %s\n"%limit)
                self.c.write_config('limit', limit)

            elif ans=="2":
                print("Current offset of shown vouchers: %s"%self.c.get_config('offset'))
                offset = input('''Enter new offset of shown vouchers:\n''').strip() or "0"
                if not offset.isdigit():
                    offset = "0"
                print("New offset of shown vouchers: %s\n"%offset)
                self.c.write_config('offset', offset)

            elif ans=="3":
                print("Current voucher package id: %s"%self.c.get_config('package'))
                package= input('''Enter new voucher package id:\n''').strip() or "1"
                if not package.isdigit():
                    package = "1"
                print("New voucher package id: %s\n"%package)
                self.c.write_config('package', package)

            elif ans=="4":
                print("Resetting configuration file.")
                if os.path.exists(CONFIG_FILEPATH):
                    os.remove(CONFIG_FILEPATH)
                self.c.write_config('reset', True)
                self.setup_configuration()

            elif ans=="5":
                ans=False

            elif ans !="":
                print("\n Not Valid Choice Try again")

    # Print all vouchers
    def print_vouchers(self):
        for code, price, time in self.c.read_vouchers():
            print("%3s %2s %s" % (code, price, time))
        print("")

    # Print server generated voucher
    def print_generated_voucher(self):
        print("")
        print("You have to activate the card before first use.")
        print("After activation the same code can be used as the")
        print("Username and Password to log in to the Hotspot.")
        print("")
        print("-----------------------")
        print("| %s |"%self.c.config['last_voucher_time'])
        print("|     %11s     |"%self.c.config['last_voucher'])
        print("-----------------------")
        print("")


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


## Add UI
if ispythonista:
    MyTableView()

else:   
    Interpreter().menu()