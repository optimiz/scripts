#! /bin/bash
# Monday, May 20 2019 - FE - Change exec of date command to $() style instead of legacy backticks and add folder variable for ease of use.
# Currently runs via administrator crontab

today=$(date '+%Y_%m_%d');
destination='/home/screenlyOSE/displays'
hdtv='1920x1080';

# Tuesday, May 21 2019 - FE - Resize original pictures to HDTV size per screenly recommendations, read them here:
# https://support.screenly.io/hc/en-us/articles/360009335693-What-content-types-are-supported-by-Screenly-OSE-
# Monday, June 03 2019 - FE - Creator using different naming convention, updated to include change, and created 'outfile' variable for detox afterward.

cd "$destination/"
for infile in DSC_????.{jpg,JPG} DSC*.JPG;
	do
	if [ -e "${infile}" ] ; then
	outfile="$destination/${infile[@]%.*}_resized_for_1080p_hdtv_screen.jpg"
	convert "${infile}" -normalize -resize "$hdtv^" -gravity center -extent "$hdtv" +profile '*' -sampling-factor 4:2:0 -quality 89 "${outfile}";
	mv "${infile}" "$destination/originals/";
	detox "${outfile}";
	fi;
	done;

exit;