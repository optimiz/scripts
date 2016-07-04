#! /bin/bash
# FE - November 17, 2015 - Compendium of physical media data recovery techniques.
# ffplay -fs -f lavfi smptehdbars=size=sxga
# Recover data, ignore bitrot, manufacturing defects, and intentional corruption.

drive=/dev/sr0
title=$(lsdvd $drive |grep 'Disc' |awk '{print $3}')
echo $title
ddrescue -n -b 2048 -d $drive "$title.iso" "$title.map"
eject $drive
stream=1
type=animation

dvdxchap -t $stream "$title.iso" > "$title.chapters"
tccat -i "$title.iso" -T $stream,-1 |pv > "$title.vob"
# Detect chapter transitions from track silence in combination with black frames, convert with $ date -d@"$timecode" -u +%H:%M:%S
# ffmpeg -i "$title.vob" -sn -af silencedetect=-50dB:d=0.1 -vf blackdetect=d=0.1:pix_th=.1 -f null -
mkvmerge -o "$title.mkv" -a 1 --default-language en "$title.vob" --chapters "$title.chapters" --title "$title"

# Optional foreign language clause...
tcextract -i "$title.vob" -x ps1 -t vob -a 0x20 |pv > "$title.ps0"
subtitle2vobsub -p "$title.ps0" -o "$title" 
# Ignore generated size and palette; player will use default color and resize bitmaps via SAR/DAR.
sed -i '/size/,/palette/s/^/#/' "$title.idx"
mkvmerge -o "$title.mkv" -a 1 --default-language zh "$title.vob" --forced-track 0:1 --language 0:en "$title.idx" --chapters "$title.chapters" --title "$title"

# Optional conversion to h264...
ffmpeg -i "$title.vob" -sn -an -vcodec h264 -tune "$type" "$title.h264"
mkvmerge -o "$title.mkv" --default-language ja "$title.h264" -D -a 2 "$title.vob" --language 0:en "$title.idx" --chapters "$title.chapters" --title "$title"

# When mpeg2 stream has (often intentional) GOP issues at onset, mkvmerge < v7.9 will hang/crash, use "ulimit -v 512000" to prevent total system lock.
# Alternatively, convert video to h.264, extract audio separately. Or, discover duration using silence/black detect and use "-ss" to skip (WALL_E).
ffmpeg -i "$title.vob" -t 1:00 -sn -af silencedetect=-50dB:d=0.1 -vf blackdetect=d=0.1:pix_th=.1 -f null -
ffmpeg -i "$title.vob" -sn -vn -acodec copy "$title.ac3"
ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -ss 00:00:01.604 -i "$title.vob" -map 0 -codec copy -f vob "remux.vob"
# When ac3 stream is not detected correctly (0 channels), increase analyze duration and probesize, remux to separate stream as necessary...
ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -i "$title.vob" -acodec copy -ab 448k -ac 6 -async 48000 "$title.ac3"
for channel in {0..3}; do tcextract -i "$title.vob" -x ac3 -a $channel |pv > "audio$channel.ac3" ;done
# When VOB has bad start frames/audio, use "-ss" to skip; the "-to" option with 5-minute duration speeds up test iterations.
ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -ss 2 -i "$title.vob" -to 5:00 -codec copy -f vob "remux.vob"

# Extract single audio stream methods...
ffmpeg -i "$title.vob" -sn -vn -map a:$stream -acodec copy "$title.ac3"
tccat -i $drive -T $stream,-1 |tcextract -x ac3 -t vob |pv > "$title.ac3"
mkvmerge -o "$title.mkv" --default-language en "$title.h264" "$title.ac3" --chapters "$title.chapters" --title "$title"

# Set a non-destructive crop mask in existing MKV...
mkvpropedit "$title.mkv" -v --edit track:v1 -s pixel-crop-top=9 -s pixel-crop-bottom=9

# Crop must be evenly divisible by 16, if not and/or is scaled to be, it will produce a terrible-looking encode.  Overcrop instead.
# The following method produces terrible-looking encodes: lr=4 # Pixels from each side, left and right. ;tb=10 # Pixels from both top and bottom.
ffmpeg -i "$title.vob" -vf crop=iw-$(($lr*2)):ih-$(($tb*2)):$lr:$tb "$title.h264"
#
# For mpeg2 streams with noticeable interlace artifacts, play with additional processing -- may interfere with or disable hardware decode.
mpv -vf yadif=frame "$title.mkv"
#
# For navigation segfaults on empty/corrupt title(s) (BRAVE) use vlc --dvdnav-menu option to determine correct stream.
# Separate by chapters -- can recover from frame issues at start/end of cells; recombine in MKV process...
stream=6; for chapter in {1..38}; do echo "Extracting: $chapter"; tccat -i "$title.iso" -T $stream,$chapter |pv > "$title$chapter.vob"; done
mkvmerge -o "$title.mkv" -a 1,2,6 --default-language en \( "$title*.vob" \) --chapters "$title.chapters" --title "$title"
#
# When audio desyncs immediately on black frame (WALL_E/UP/STARTREK1/RATATOUILLE/DARKKNIGHT), pull video forward so first frame is a _complete_ I-frame and audio forward -- offset with/to video black frame; else, hardware video decode will fail and fallback to software.  Examples...
mkvmerge -o "$title.mkv" -a 1,4 -y 0:-37262 -y 1:-33007 -y 4:-33007 --default-language en "$title.vob" --chapters "$title.chapters" --title "$title"
mkvmerge -o "$title.mkv" -y 0:-37000 -y 1:-31500 -y 2:-31500 -y 3:-31500 --default-language en "$title.vob" --chapters "$title.chapters" --title "$title"

# When lsdvd and vlc --dvdnav-menu segfault or fail (KICKASS), use 7z or isoinfo to find correct stream (hint: ignore non-DVD compliant file sizes).
# For titles with commentary track(s) that play over studio intros (DISTRICT9), find unfucked initial chapter 1 in ~99 titles, then combine with remaining chapters using process used for empty/corrupt title 3.
stream=54; for chapter in {01}; do echo "Extracting: $chapter"; tccat -i "$drive$title.iso" -T $stream,$chapter |pv > "S$stream$title$chapter.vob"; done
stream=1; for chapter in {02..28}; do echo "Extracting: $chapter"; tccat -i "$drive$title.iso" -T $stream,$chapter |pv > "S$stream$title$chapter.vob"; done

for iso in LOTR3 LOTR2 LOTR1 ;do ./getit.sh $iso 1 ;done
for title in LOTR3 LOTR2 LOTR1 ;do ionice -c3 mkvmerge -o "$title.mkv" --default-language en "$title.vob" --chapters "$title.chapters" --title "$title" ;done

# for title in *.vob; do mkvmerge -o "${title[@]%.*}.mkv" --default-language en $title --chapters "${title[@]%.*}.chapters" --title "$title"; done
# for title in *.mkv; do ionice -c3 ffmpeg -i "$title" -sn -an -vcodec h264 -tune "$type" "${title[@]%.*}.h264"; done
# for title in *.vob; do ionice -c3 mkvmerge -o "${title[@]%.*}.mkv" "${title[@]%.*}.h264" -D -a 1 --default-language en "${title[@]%.*}.vob"; done

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
#
# When ddrescue projects more than a 20m run time (TITANAE), use two-pass method with a different drive outputting to original recovery file.
ddrescue -m "$title.map" -n -b 2048 -c 1 -r 1 -d $drive "$title.iso" "$title-2nd-pass.map"
# For discs with >1GB unfinished area (NYSM,RED2,KICKASS2,CITW) outside the TOC, exit ddrescue; only bad streams are in the unifished area.
# These discs often have a *** Zero check failed in src/ifo_read.c vmgi_mat->zero_6 error message.
# However, discs with ~1GB error area (YOURENEXT,BATTLELA) will segfault vlc and/or play incorrect title unless unread area is reduced to ~256k.
