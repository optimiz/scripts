#!/bin/bash
# Script name: old2mkv.sh
# Purpose: Convert outdated anime containers to MKV format, combining external subtitles.
ionice -c3 -p$$

for file in *.{ogm,divx};
do
	if [ -e "$file" -a ! -e "${file[@]%.*}.mkv" ]; then
		basefile="${file[@]%.*}";
		case ${file##*.} in
			ogm )
			mkvmerge -o "${basefile}.mkv" --language 1:jpn --language 2:eng "$file" --language 0:eng  "${basefile}.ssa" \
			&& \
			touch -r "$file" "${basefile}.mkv";
			;; 
			divx )
			mkvmerge -o "${basefile}.mkv" --language 1:jpn "$file" \
			&& \
			touch -r "$file" "${basefile}.mkv";
			;; 
			* )
			echo 'Nothing to do.';
			;;
		esac;
	fi;
done
#exit

# Following revised from here: http://www.commandlinefu.com/commands/tagged/1978/cksfv

for file in *.mkv; do mv "$file" "${file[@]%.*} [$(cksfv -b -q "$file" | egrep -o "\b[A-F0-9]{8}\b$")].${file##*.}"; done
