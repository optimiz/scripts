#!/bin/bash
# Script name: old2mkv.sh
# Purpose: Convert outdated containers to MKV format, combining external subtitles.
ionice -c3 -p$$

for file in *.{ogm,divx,vob};
do
	if [ -e "$file" -a ! -e "${file[@]%.*}.mkv" ]; then
		basefile="${file[@]%.*}";
		case ${file##*.} in
			ogm )
			mkvmerge -o "${basefile}.mkv" --default-language en --language 1:ja "$file" "${basefile}.ssa" 
			;; 
			divx )
			mkvmerge -o "${basefile}.mkv" --default-language en --language 1:ja "$file" 
			;;
			vob )
			mkvmerge -o "${basefile}.mkv" --default-language en "$file" 
			;;
			* )
			echo 'Nothing to do.';
			;;
		esac;
		touch -r "$file" "${basefile}.mkv";
	fi;
done
#exit

# Following revised from here: http://www.commandlinefu.com/commands/tagged/1978/cksfv

# for file in *.mkv; do mv "$file" "${file[@]%.*} [$(cksfv -b -q "$file" | egrep -o "\b[A-F0-9]{8}\b$")].${file##*.}"; done
