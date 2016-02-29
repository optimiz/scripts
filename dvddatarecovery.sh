#! /bin/bash
# FE - November 17, 2015 - Recover data from physical media.
# Recover data, ignore bitrot, manufacturing defects, and intentional corruption.
# ffplay -fs -f lavfi smptehdbars=size=sxga

drive=/dev/sr0
title=$(lsdvd $drive |grep 'Disc' |awk '{print $3}')
echo $title
ddrescue -n -b 2048 -d $drive "$title.iso" "$title.map"
eject $drive
stream=1
type=animation

# For excessive disc errors, reduce recovery size to one write per read, one retry per error.
# ddrescue -n -b 2048 -c 1 -r 1 -d $drive "$title.iso" "$title.map"
#
# Example output (Man of Steel) with original recovery options...
#rescued:   441145 kB,  errsize:   7687 MB,  current rate:     2048 B/s
#   ipos:   427286 kB,   errors:     127,    average rate:    1387 kB/s
#   opos:   427286 kB,    time since last successful read:       0 s
# Example output (Man of Steel) with replacement options...
#rescued:     8128 MB,  errsize:       0 B,  current rate:     856 kB/s
#   ipos:     8128 MB,   errors:       0,    average rate:    3836 kB/s
#   opos:     8128 MB,    time since last successful read:       0 s

dvdxchap -t $stream "$title.iso" > "$title.chapters"
tccat -i "$title.iso" -T $stream,-1 |pv > "$title.vob"
# Detect chapter transitions from track silence in combination with black frames, convert with $ date -d@"$timecode" -u +%H:%M:%S
# ffmpeg -i "$title.vob" -sn -af silencedetect=-50dB:d=0.1 -vf blackdetect=d=0.1:pix_th=.1 -f null -
mkvmerge -o "$title.mkv" -a 1 --default-language en "$title.vob" --chapters "$title.chapters" --title "$title"

# Optional foreign language clause...
tcextract -i "$title.vob" -x ps1 -t vob -a 0x20 |pv > "$title.ps0"
subtitle2vobsub -p "$title.ps1" -o "$title" 
# Ignore generated size and palette; player will use default color and resize bitmaps via SAR/DAR.
sed -i '/size/,/palette/s/^/#/' "$title.idx"
mkvmerge -o "$title.mkv" -a 1 --default-language zh "$title.vob" --language 0:en "$title.idx" --chapters "$title.chapters" --title "$title"

# Optional conversion to h264...
ffmpeg -i "$title.vob" -sn -an -vcodec h264 -tune "$type" "$title.h264"
mkvmerge -o "$title.mkv" --default-language ja "$title.h264" -D -a 2 "$title.vob" --language 0:en "$title.idx" --chapters "$title.chapters" --title "$title"

# When mpeg2 stream has (often intentional) GOP issues at onset, mkvmerge < v7.9 will hang/crash, can use "ulimit -v 512000" to prevent lockups.
# Alternatively, convert video to h.264, extract audio stream separately. Or, discover duration using silence/black detect and use "-ss" to skip.
# ffmpeg -i "$title.vob" -t 1:00 -sn -af silencedetect=-50dB:d=0.1 -vf blackdetect=d=0.1:pix_th=.1 -f null -
ffmpeg -i "$title.vob" -sn -vn -acodec copy "$title.ac3"
ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -ss 00:00:01.604 -i "$title.vob" -map 0 -codec copy -f vob "remux.vob"
# When ac3 stream is not detected correctly (0 channels), increase analyze duration and probesize, remux to separate stream as necessary...
ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -i "$title.vob" -acodec copy -ab 448k -ac 6 -async 48000 "$title.ac3"
# When VOB has bad start frames/audio, use "-ss" to skip; the "-to" option with 5-minute duration speeds up test iterations.
# ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -ss 2 -i "$title.vob" -to 5:00 -codec copy -f vob "remux.vob"

# Extract single audio stream methods...
ffmpeg -i "$title.vob" -sn -vn -map a:$stream -acodec copy "$title.ac3"
tccat -i $drive -T $stream,-1 |tcextract -x ac3 -t vob |pv > "$title.ac3"
mkvmerge -o "$title.mkv" --default-language en "$title.h264" "$title.ac3" --chapters "$title.chapters" --title "$title"

# Set a non-destructive crop mask in existing MKV...
mkvpropedit "$title.mkv" -v --edit track:v1 -s pixel-crop-top=9 -s pixel-crop-bottom=9

# Crop must be evenly divisible by 16, if not and/or is scaled to be, it will produce a terrible-looking encode.  Overcrop instead.
# The following method produces terrible-looking encodes: lr=4 # Pixels from each side, left and right. ;tb=10 # Pixels from both top and bottom.
# ffmpeg -i "$title.vob" -vf crop=iw-$(($lr*2)):ih-$(($tb*2)):$lr:$tb "$title.h264"
#
# For mpeg2 streams with noticeable interlace artifacts, play with additional processing...
# mpv -vf yadif=frame "$title.mkv"
#
# For navigation segfaults on empty/corrupt title 3 (Brave) use vlc --dvdnav-menu option to determine correct stream; then...
# Separate by chapters -- can recover from frame issues at start/end of cells; recombine in MKV process...
# stream=6; for chapter in {1..38}; do echo "Extracting: $chapter"; tccat -i "$title.iso" -T $stream,$chapter |pv > "$title$chapter.vob"; done
# mkvmerge -o "$title.mkv" -a 1,2,6 --default-language en \( "$title*.vob" \) --chapters "$title.chapters" --title "$title"
# When audio desyncs immediately (UP), pull audio and video forward based on black frame end so start frame is a complete (starting) I-frame.
# mkvmerge -o "$title.mkv" -a 1,4 -y 0:-37262 -y 1:-33007 -y 4:-33007 --default-language en "$title.vob" --chapters "$title.chapters" --title "$title"
