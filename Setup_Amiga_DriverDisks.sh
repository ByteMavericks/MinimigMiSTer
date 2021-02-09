#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.



# ========= OPTIONS ==================
URL="https://github.com"
FILEURL="http://aminet.net/util/arc/lha.run"
CURL_RETRY="--connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5 --show-error"

ALLOW_INSECURE_SSL="true"

# ========= CODE STARTS HERE =========
# get the name of the script, or of the parent script if called through a 'curl ... | bash -'

# test network and https by pinging the target website 
SSL_SECURITY_OPTION=""
curl ${CURL_RETRY} "${URL}" > /dev/null 2>&1
case $? in
	0)
		;;
	60)
		if [[ "${ALLOW_INSECURE_SSL}" == "true" ]]
		then
			SSL_SECURITY_OPTION="--insecure"
		else
			echo "CA certificates need"
			echo "to be fixed for"
			echo "using SSL certificate"
			echo "verification."
			echo "Please fix them i.e."
			echo "using security_fixes.sh"
			exit 2
		fi
		;;
	*)
		echo "No Internet connection"
		exit 1
		;;
esac

# download and execute the latest mister_updater.sh
echo "Downloading file lists for Disks 1 and 2"
curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location \
        -O https://github.com/ByteMavericks/MinimigMiSTer/raw/main/resources/D1_Download_URLs \
        -O https://github.com/ByteMavericks/MinimigMiSTer/raw/main/resources/D2_Download_URLs \
        -O https://github.com/ByteMavericks/MinimigMiSTer/raw/main/resources/MiSTerUtils.adf

dos2unix D1_Download_URLs
dos2unix D2_Download_URLs
readarray -t D1 < D1_Download_URLs
readarray -t D2 < D2_Download_URLs

#Mount our new thing
cp MiSTerUtils.adf Picasso96.adf
TMPMOUNT=$(mktemp -d)
echo "Mounting Disk1 ADF on ${TMPMOUNT}"
mount -t affs MiSTerUtils.adf ${TMPMOUNT} -o loop,verbose
df ${TMPMOUNT}
echo "Downloading D1 setup files (${#D1[@]}) and adding to disk"
for item in ${D1[@]}
do
		echo "...${item}"
		curl --silent ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -O ${item}
		cp ${item##*/} ${TMPMOUNT}
done
sync
df ${TMPMOUNT}
sync
umount ${TMPMOUNT}
TMPMOUNT=$(mktemp -d)
echo "Mounting Disk2 ADF on ${TMPMOUNT}"
mount -t affs Picasso96.adf ${TMPMOUNT} -o loop,verbose
df ${TMPMOUNT}
echo "Downloading D2 setup files (${#D2[@]}) and adding to disk"

for item in ${D2[@]}
do
		echo "...${item}"
		curl --silent ${CURL_RETRY} ${SSL_SECURITY_OPTION} --fail --location -O ${item}
		cp ${item##*/} ${TMPMOUNT}
		rm ${item##*/}
done
sync
df ${TMPMOUNT}
sync
umount ${TMPMOUNT}

if [[ ! -d "/media/fat/games/Amiga/setup" ]]
	then
		mkdir /media/fat/games/Amiga/setup
fi

cp Picasso96.adf /media/fat/games/Amiga/setup/
cp MiSTerUtils.adf /media/fat/games/Amiga/setup/
exit 0
