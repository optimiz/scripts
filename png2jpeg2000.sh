#! /bin/bash
# Thursday, October 15 2015 - Batch convert large PNG collection to lossless JPEG2000 for archival purposes.
# Note: Use "find" to feed files recursively.
# Example: find ~/ -type f -iname "2015*png" -exec png2jpeg2000.sh {} \;

if [ -z "$1" ]; then cmdline="*.png";
	elif [ -d "$1" ]; then cmdline="${1%/}/*.png";
	elif [ -e "$1" ]; then cmdline="$1"
#	else echo "Invalid command line."; exit 1;
	else cmdline="$1"
fi;

IFS=$'\n\b'

for file in ${cmdline}; 
do 
	outfile="${file[@]%.*}.jp2";
	if [ -e "${file}" -a ! -e "${outfile}" ]; then
		echo "Convert ${file} to lossless JPEG2000.";
		gm convert "${file}" -compress lossless "${outfile}";
			if [[ $(stat -c%s "${file}") -ge $(stat -c%s "${outfile}") ]]; then
				echo "Copy original metadata to ${outfile}.";
				exiftool -overwrite_original -tagsfromfile "${file}" "${outfile}";
				touch -r "${file}" "${outfile}";
#				rm -v "${file}";
			else
				echo "JPEG 2000 is larger than PNG, deleting."
				rm -v "${outfile}";
			fi;
	elif [ -e "${outfile}" ]; then 
		echo "JPEG 2000 ${outfile} already exists."
	fi;
done

IFS=$'\040\t\n'
