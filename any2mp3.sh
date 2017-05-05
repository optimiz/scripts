#!/bin/bash
# Script name: any2mp3.sh
# FE - Sunday, February 01 2015 15:32 - Refactored 2009 "wav to mp3" script into "any to mp3"
# FE - Saturday, March 21 2009 12:12 - Settings for 3.98 to mirror 3.90 settings from 2002...
LAME_OPTS="-m s -q 0 -V 0 -b 32 -B 320 --lowpass -1 --highpass -1"
# FE - Sunday, December 27 2009 14:29 - Autotrim silence from front and back...
SOX_OPTS="--multi-threaded --buffer 10240000 silence 1 1 0.01% reverse silence 1 1 0.01% reverse norm -0.03"
# --temp /media/ -V3
# FE - Tuesday, October 04 2016 15:48 - Two channel, signed int, little-endian
# [NOTE: tcextract auto-converts(?) big-endian DVD-PCM to native (host) endian.]
RAW_OPTS="-c 2 -e signed-integer -L -b 16"
# FE - Sunday, August 21 2016 18:38 - For mono (Bluetooth speaker/headphones), insert "remix 1,2" or "channels 1" before norm directive
# in sox options and remove "-m s" from lame options; alternatively, only replace "-m s" with "-m" in lame options instead.
# [NOTE: Use sox over lame for mono conversions to make use of sox' internal 32bit conversion process.]
# FE - Sunday, August 21 2016 23:16 - Output 24bit from sox to avoid dither after normalizing -- lame accepts up to 32bit and FFTs don't need dithered input.
OUT_OPTS="-b 24 -t wav"

ionice -c3 -p$$

function conversion {
	if [ -e "$file" -a ! -e "${file[@]%.*}.mp3" ]; then
		song="${file[@]%.*}.mp3";
		case "${file##*.}" in
			flac )
			sox -t flac "$file" ${OUT_OPTS} - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			wav )
			sox -t wav "$file" ${OUT_OPTS} - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			aif|aiff )
			sox -t aiff "$file" ${OUT_OPTS} - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			m4a|aac )
			faad -q -w -d -f 2 "$file" \
				| sox -t raw ${RAW_OPTS} -r 44100 - ${OUT_OPTS} - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
			;;
			vob )
			tcextract -i "$file" -x pcm -a 0 \
				| sox -t raw ${RAW_OPTS} -r 48000 - ${OUT_OPTS} - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
				# ffmpeg -i "$file" -sn -vn -compression_level 8 "${file[@]%.*}.flac"
			;;
			raw|pcm|lpcm )
			sox -t raw ${RAW_OPTS} -r 48000 "$file" ${OUT_OPTS} - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
				# play -t raw ${RAW_OPTS} -r 48000 "$file";
				flac -8 --delete-input-file --channels=2 --sign=signed --bps=16 --sample-rate=48000 --endian=little "$file";
			;;
			dts|ac3 )
			ffmpeg -i "$file" -af aresample=resampler=soxr:precision=28:cheby=1:dither_method=triangular_hp \
				-lfe_mix_level 1 -acodec pcm_s32le -ac 2 -af "pan=stereo|FL=FL+LFE|FR=FR+LFE" -f wav - \
				| sox -t wav - -t wav - ${SOX_OPTS} \
				| lame ${LAME_OPTS} - "$song";
				# sox "$file" "split-track.wav" silence 1 1.0 0.1% 1 1.0 0.1% : newfile : restart;
			;;
			* )
			echo 'Nothing to do.';
			;;
		esac;
	fi;
}

# Tuesday, March 07 2017 - Speed up processing using parallel...
# parallel -j 2 -i nice -n 18 ionice -c2 time ~/Scripts/any2mp3.sh {} -- *.wav

if [ -e "$1" ];
	then file="$1";
		conversion && rm -v "$file";
	else
		for file in *.{flac,wav,*pcm,m4a,vob,aac,aif*,raw,dts,ac3};
			do
				conversion # && rm -v "$file";
			done;
fi;

# Thursday, November 03 2016
# ffmpeg -i "$file" -filter_complex "channelsplit=channel_layout=5.1[FL][FR][FC][LFE][BL][BR]" -acodec pcm_s32le -map "[FL]" front_left.wav -acodec pcm_s32le -map "[FR]" front_right.wav -acodec pcm_s32le -map "[FC]" front_center.wav -acodec pcm_s32le -map "[LFE]" lfe.wav -acodec pcm_s32le -map "[BL]" back_left.wav -acodec pcm_s32le -map "[BR]" back_right.wav
# Tuesday, November 15 2016 - Mono output (for comedy concerts)
# ffmpeg -i "$file" -af "pan=mono|FC=FC" -vn -acodec mp3

