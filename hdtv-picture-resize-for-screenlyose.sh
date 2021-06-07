#!/bin/bash
# Monday, May 20 2019 - FE - Change exec of date command to $() style instead of legacy backticks and add folder variable for ease of use.
today=$(date '+%Y_%m_%d');
staging='/media/screenlymediafiles/staging';
destination='/media/cbmscreenly';
source='/media/photos/For_Displays';
hdtv='1920x1080';

# Tuesday, May 21 2019 - FE - Resize original pictures to HDTV size per screenly recommendations, read them here:
# https://support.screenly.io/hc/en-us/articles/360009335693-What-content-types-are-supported-by-Screenly-OSE-
# Monday, June 03 2019 - FE - Creator using different naming convention, updated to include change, and created 'outfile' variable for detox afterward.
# Monday, June 07 2021 - FE - Institute image conversion advice from Google developer page: https://developers.google.com/speed/docs/insights/OptimizeImages

if [ -d "$source" ]; then
	mkdir -p "$staging";
	rsync -hurt --delete --exclude='Thumbs.db' "$source"/* "$staging/";

	pushd "$staging"
		for infile in *.{jpg,JPG,jpeg,JPEG};
			do
				if [ -e "${infile}" ] ; then
					outfile="${infile[@]%.*}_resized_for_1080p_hdtv_screen.jpg";
					convert "${infile}" -normalize -resize "$hdtv^" -gravity center -extent "$hdtv" +profile '*' -sampling-factor 4:2:0 -quality 85 -define jpeg:dct-method=float -interlace JPEG -colorspace sRGB "${outfile}";
					jpegoptim "${outfile}";
					touch -r "${infile}" "${outfile}";
					exiftool -P '-filename<CreateDate' '-filename<filemodifydate' -d %Y-%m-%d-%Hh%Mm%S%%-c.%%le "${outfile}";
					rm "${infile}";
				fi;
			done;
	popd

	rsync -hurt --delete "$staging/" '/media/screenlymediafiles/constant/' "$destination";
fi

# Friday, April 16 2021 - FE - Cleanup staging area.
if [ -d "$staging" ]; then rm -rf "$staging"; fi

exit;
