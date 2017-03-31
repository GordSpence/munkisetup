#!/bin/bash
# This Script configures Munki upon initial deployment. It assumes that you have already run the pkg installer for Managed Software Centre and rebooted. The script will determine the serial number of the computer, verify that a manifest with the serial number is present on the server, and then configure Munki with the settings we want. If it can't find the manifest we want (it hasn't been created, or isn't reachable), the script fails with an error.

SOFTWAREREPOURL="https://munki.server/munki_repo"
SERIAL="$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')"

echo "Running Munki to generate ManagedInstalls.plist..."
/usr/local/munki/managedsoftwareupdate -a

echo "Setting Munki repository to "${SOFTWAREREPOURL}"..."
/usr/bin/defaults write /Library/Preferences/ManagedInstalls.plist SoftwareRepoURL "${SOFTWAREREPOURL}"

echo "Serial number is "${SERIAL}". Checking that the Munki server has a manifest for this serial number..."

#Download manifest from munki repo. If I receive a HTML file (e.g. not a plist) from the server (likely a 404 page), exit the script and tell user to create manifest. If the file is a plist, display nested manifest list and proceed with configuration.

curl -s "${SOFTWAREREPOURL}"/manifests/"${SERIAL}" -o /tmp/"${SERIAL}".plist

if grep -q "<!DOCTYPE HTML" /tmp/"${SERIAL}".plist
	then
		echo "ERROR: Manifest can't be found on server. Has it been created?"
		exit 1
	
	else
		INCLUDED_MANIFESTS="$(/usr/bin/defaults read /tmp/"${SERIAL}".plist included_manifests)"
		MANIFEST_DISPLAYNAME="$(/usr/bin/defaults read /tmp/"${SERIAL}".plist display_name)"
		echo "Manifest found for "${MANIFEST_DISPLAYNAME}". Includes the following nested manifest(s):"
		echo "${INCLUDED_MANIFESTS}"
		
		echo "Setting local manifest to "${SERIAL}"."
	/usr/bin/defaults write /Library/Preferences/ManagedInstalls.plist ClientIdentifier "${SERIAL}"
		echo "Enabling installation of Apple Software Updates..."
	/usr/bin/defaults write /Library/Preferences/ManagedInstalls.plist InstallAppleSoftwareUpdates -bool True
		echo "Enabling Apple Software Updates to install without requiring user intervention..."
	/usr/bin/defaults write /Library/Preferences/ManagedInstalls.plist UnattendedAppleUpdates -bool True
		echo "Running first check for updates from Munki (this will take a while if installations are happening)..."
	/usr/local/munki/managedsoftwareupdate -a
		echo "Cleaning up temporary files..."
		/bin/rm /tmp/"${SERIAL}".plist
		echo "Done."
fi
exit 0