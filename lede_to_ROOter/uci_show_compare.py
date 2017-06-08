# Add lede pacakges
def read_settings(fname):
    with open(fname) as f:
        flines = f.readlines()

    settings = []
    for i in flines:
        setting = i.strip()
        settings.append(setting)
    return settings

lede = read_settings("uci_show__lede-17.01.1-ar71xx-generic-gl-ar150.txt")
rooter = read_settings("uci_show__lede-gl-ar150-GO2017-04-15.txt")

# Find which settings in lede, which is not in go
remove = []

for p in lede:
    if p not in rooter:
        print p,
        remove.append(p)

print("Nr of settings in lede but not in GoldenOrb is: %s")%len(remove)
removefile = open('uci_show_compare_remove.txt', 'w')
for item in remove:
    removefile.write("%s\n" % item)
removefile.close()

add = []
for p in rooter:
    if p not in lede:
        add.append(p)

print("Nr of settings in GoldenOrb but not in lede is: %s")%len(remove)
addfile = open('uci_show_compare_add.txt', 'w')
for item in add:
    addfile.write("%s\n" % item)
addfile.close()
