#!/bin/bash
# SuspendDelayMngr.sh

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


#Check for full screen window every 1 minutes by default
CHECK_DELAY=60

if [[ $1 ]]; then

	if [[ "$1" == "--help" ]]; then
		echo "Usage: SuspendDelayMngr.sh [CHECK_DELAY] [SCREENSERVER_TIMEOUT]"
		echo "Defaults: CHECK_DELAY = 60"
		echo "SCREENSERVER_TIMEOUT = 300"

		exit
	fi

	CHECK_DELAY=$1

fi

#Off screen after 5 minutes by default
SCREENSERVER_TIMEOUT=300

if [[ $2 ]]; then
	SCREENSERVER_TIMEOUT=$2
fi

checkForFullScreenWindows()
{
	WINDOWS=$(wmctrl -l)

	WINDOWS_IDS=$(echo "$WINDOWS" | cut -c-10)

	WINDOWS_IDS_ARRAY=(${WINDOWS_IDS//\n/})

	for i in "${!WINDOWS_IDS_ARRAY[@]}"
	do
	    NET_WM_STATE=$(xprop -id ${WINDOWS_IDS_ARRAY[i]} _NET_WM_STATE)
		
	    if [[ $NET_WM_STATE == *_NET_WM_STATE_FULLSCREEN* ]]
	    then
	    	#return 0 when syccess (true)
	    	return 0

	    	break
	    fi

	done

	#return 1 when false
	return 1;
}

checkForPowerManagerIsRunning()
{
	if [[ $(ps -ef | grep -v grep | grep xfce4-power-manager) != "" ]]
	then
		return 0
	fi

	return 1
}

# +-------------------------+---------------------+-------------+
# | FullScreen Window Exist | Power Manager Works |   Action    |
# +-------------------------+---------------------+-------------+
# |                       0 |                   0 | Activate PM |
# |                       0 |                   1 | nop         |
# |                       1 |                   0 | nop         |
# |                       1 |                   1 | Close PM    |
# +-------------------------+---------------------+-------------+
while true
do

	checkForFullScreenWindows
	IS_FS_WINDOW_EXIST=$?

	checkForPowerManagerIsRunning
	IS_PM_RUNNING=$?

	if [[ ( $IS_FS_WINDOW_EXIST -eq 0 ) && ( $IS_PM_RUNNING -eq 0 ) ]]
	then
		echo "Window with _NET_WM_STATE_FULLSCREEN has been found:"
		echo "$(wmctrl -l | grep "${WINDOWS_IDS_ARRAY[i]}")"
		echo "Deactivating xfce4-power-manager..."
		echo "xset s off..."
		echo

		xfce4-power-manager --quit
		xset s off
	fi

	if [[ ( $IS_FS_WINDOW_EXIST -ne 0 ) && ( $IS_PM_RUNNING -ne 0 ) ]]
	then
		echo "Activating xfce4-power-manager..."
		echo "xset s on..."
		echo "xset s" $SCREENSERVER_TIMEOUT"..."
		echo
		
		xfce4-power-manager
		xset s on
		xset s $SCREENSERVER_TIMEOUT
	fi


	sleep $CHECK_DELAY

done