#!/bin/sh
#brew services start sleepwatcher

while :
do
	system_profiler SPThunderboltDataType | grep -q "Elgato"
	if [ $? -eq 0 ]; then
		timestamp=$(pmset -g log | grep -i "wake"  | grep "powerd" | grep PID | tail -n 1 | awk '{print $1 " " $2}')
		ts_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$timestamp" "+%s")
		now_epoch=$(date "+%s")
		diff=$(( now_epoch - ts_epoch ))
		if [ "$diff" -lt 20 ]; then
			/opt/homebrew/bin/SwitchAudioSource -t input -s "USB audio CODEC"
			/usr/bin/osascript -e "set volume input volume 100"
			/opt/homebrew/bin/SwitchAudioSource -t output -s "DELL U2719D"
			sleep 20
		fi
	fi

	sleep 5
done
