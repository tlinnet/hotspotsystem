# Add lede pacakges
def read_packages(fname):
    with open(fname) as f:
        flines = f.readlines()

    packages = []
    for i in flines:
        package = i.split(" ")[0]
        packages.append(package)
    return packages

lede = read_packages("opkg_list-installed__lede-17.01.1-ar71xx-generic-gl-ar150.txt")
rooter = read_packages("opkg_list-installed__lede-gl-ar150-GO2017-04-15.txt")

# Find which packages in lede, which is not in go
remove = []

for p in lede:
    if p not in rooter:
        remove.append(p)
print("Nr of packages in lede but not in GoldenOrb is: %s")%len(remove)

add = []
for p in rooter:
    if p not in lede:
        add.append(p)

addfile = open('opkg_list_compare_add.txt', 'w')
for item in add:
    addfile.write("opkg install %s\n" % item)
addfile.close()
