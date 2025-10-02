#!/bin/sh
if [ -z $1 ]
then
	echo Specify input file
	exit 1
fi

IN_FILE=$1
shift

os="$(uname -s 2>/dev/null || echo unknown)"

if [ "$os" = "Darwin" ]
then
	CAFFEINATE="caffeinate -i"
	ENCODER=h264_videotoolbox
else
	ENCODER=libx264
fi

start_time=$(date +%s)
$CAFFEINATE ffmpeg -y -i "$IN_FILE" -c:v $ENCODER -b:v 9M -preset slow -crf 18 -c:a copy -c:s copy $@ "${IN_FILE%.*}.x264.mkv"
end_time=$(date +%s)
duration=$((end_time - start_time))

echo
echo
echo Duration: $duration sec
