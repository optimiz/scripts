#! /bin/bash
# FABIAN - Thursday, October 15 2015 - Automate PNG to lossless JPEG2000 conversion.
# Note: This script is not whitespace safe and will fail quietly; use "find" to feed it.
# Example: find . -type f -iname "2015*Horrible*png" -exec png2jpeg2000.sh {} \;

if [ -z "$1" ]; then cmdline="*.png";
	elif [ -d "$1" ]; then cmdline="${1%/}/*.png";
	elif [ -e "$1" ]; then cmdline="$1"
#	else echo "Invalid command line."; exit 1;
	else cmdline="$1"
fi;

for file in "$cmdline"; 
do
	if [ -e "$file" -a ! -e "${file[@]%.*}.jp2" ]; then
		outfile="${file[@]%.*}.jp2";
		echo "Convert $file to lossless JPEG2000.";
		gm convert "$file" -compress lossless "$outfile";
			if [[ $(stat -c%s "$file") -ge $(stat -c%s "$outfile") ]]; then
				echo "Copy original metadata to $outfile.";
				exiftool -overwrite_original -tagsfromfile "$file" "$outfile";
				touch -r "$file" "$outfile";
#				rm "$file";
			else
				echo "JPEG 2000 is larger than PNG, deleting."
				rm -v "$outfile";
			fi;
	fi;
done
