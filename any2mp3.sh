#!/bin/bash
# Script name: any2mp3.sh
# FE - Sunday, February 01 2015 15:32 - Refactored 2009 "wav to mp3" script into "any to mp3"
# FE - Saturday, March 21 2009 12:12 - Settings for 3.98 to mirror 3.90 settings from 2002...
LAME_OPTS="-m s -q 0 -V 0 -b 32 -B 320 --lowpass -1 --highpass -1"
# FE - Sunday, December 27 2009 14:29 - Autotrim silence from front and back...
SOX_OPTS="-V3 --buffer 10240000 silence 1 1 0.01% reverse silence 1 1 0.01% reverse norm -0.03"
# FE - Sunday, August 21 2016 18:38 - For mono (Bluetooth speaker/headphones), insert "remix 1,2" or "channels 1" before norm directive
# in sox options and remove "-m s" from lame options; alternatively, only replace "-m s" with "-a" in lame options instead.
# [NOTE: Use sox over lame for mono conversions to make use of sox' internal 32bit conversion process.]
# FE - Sunday, August 21 2016 23:16 - Output 24bit from sox to avoid dither after normalization -- lame accepts up to 32bit and transforms don't need dithered input.
ionice -c3 -p$$

for file in *.{flac,wav,m4a,vob,aac,aif*};
do
	if [ -e "$file" -a ! -e "${file[@]%.*}.mp3" ]; then
		song="${file[@]%.*}.mp3";
		case "${file##*.}" in
			flac )
			sox -t flac "$file" -b 24 -t wav - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;; 
			wav )
			sox -t wav "$file" -b 24 -t wav - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			aif|aiff )
			sox -t aiff "$file" -b 24 -t wav - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;; 
			m4a|aac )
			faad -q -w -d -f 2 "$file" \
				| sox -t raw -c 2 -e signed-integer -L -r 44100 -b 16 - -b 24 -t wav - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			vob )
			tcextract -i "$file" -x pcm -a 0 \
				| sox -t raw -c 2 -e signed-integer -L -r 48000 -b 16 - -b 24 -t wav - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			* )
			echo 'Nothing to do.';
			;;
		esac;
	fi;
done
