# munkisetup
# This Script configures Munki upon initial deployment. It assumes that you have already
# run the pkg installer for Managed Software Centre and rebooted. The script will 
# determine the serial number of the computer, verify that a manifest with the serial 
# number is present on the server, and then configure Munki with the settings we want. If 
# it can't find the manifest we want (it hasn't been created, or isn't reachable), the 
# script fails with an error.
