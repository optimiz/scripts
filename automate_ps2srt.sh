#! /bin/bash
# Thursday, February 04 2016 - FE - Automate DVD private stream (PS) subtitle conversion to SRT.
# tcextract -i "$title.vob" -x ps1 -t vob -a 0x20 |pv > "$title.ps0"

if [ -e "$1" ]; then infile="$1"
	else echo "Specify file to extract subtitles/captions." && exit 1;
fi;

#trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP

function get_subtitles {

	tmpdir=$(mktemp -d) || exit 1
	cp "$infile" "$tmpdir"
	pushd "$tmpdir"

	# Convert PS to IDX/SUB for BDSup2Sub
#	subtitle2vobsub -p "$infile" -o "$basefile"
	# Convert PS to SRTX/PGM for srttool and graphicsmagick; NOTE: This tool outputs correct timing, but incorrect frames (doubles, missing, etc.)
	subtitle2pgm -P -i "$infile" -o "$basefile"
	# Convert IDX/SUB to XML/PNG; NOTE: This tool outputs correct frames; unfortunately, this tool doesn't support PS directly.
#	java -jar /home/user/Download/BDSup2Sub.jar -o "$basefile.xml" "$basefile.idx"

	# Prepare PNG frames for OCR -- tesseract (leptonica) doesn't properly detect characters without processing -- due to transparency??
	# NOTE: Graphicsmagick v1.3.20 doesn't support flatten option as a mogrify option, must convert instead.

	# Replace "for loop" with moreutils-parallel (not GNU parallel) for faster processing.
	# for pics in "$infile"*.png; do subs="$pics.pgm"; gm convert "$pics" -contrast -fuzz 10% -transparent grey -flatten "$subs"; tesseract "$subs" "$subs"; done

#	parallel -i gm convert {} -contrast -fuzz 10% -transparent grey -flatten {}.pgm -- $basefile*.png
	parallel -i tesseract {} {} -- $basefile*.pgm

	# Modify the SRTX to refer to the OCR output from the processed frames.
#	sed -i "s/$basefile/$basefile\_/g;s/pgm/png.pgm/g" "$basefile.srtx"
	# Convert SRTX/OCR'd text to SRT for further manipulation in a subtitle editor.
	srttool -s -i "$basefile.srtx" -o "$basefile.srt" 
	# tmpdir is deleted on exit trap, no need for manual remove.
	# rm "$infile"*.{png,pgm,idx,xml,srtx,txt,sub}
eom *.pgm
	popd
	# mv  "$tmpdir/$infile.srt" "${infile[@]%.*}.srt"
	# awk '!NF{print}/[a-z]/{printf "%s ", $0;next}1' "$tmpdir/$infile.srt" > "${infile[@]%.*}.srt"
	# Remove word wrap on subtitles; most player subtitle decoders perform sentence and word-wrapping automatically and admirably.
	awk 'BEGIN {RS=ORS=""; FS=OFS="\n"}{print $1,$2,$3; for (i=4;i<=NF;i++) printf " %s", $i; print "\n\n"}' "$tmpdir/$basefile.srt" > "$basefile.srt"

	# aspell -d en -c "${infile[@]%.*}.srt"
}

function get_captions {
	# Extract closed captioning (EIA-608) and convert to SRT.
	# Sadly, CC often doesn't include "forced subtitle" foreign language translations.
	# Also, the extracted time cues and duration are often very, very, VERY wrong!
	ffmpeg -f lavfi -i "movie=$infile[out0+subcc]" -map s -f srt "$basefile.cc"
	# Remove 40-character standard word wrap; FIXME: overlapping/multiple speakers should not be unword-wrapped.
	awk -i inplace 'BEGIN {RS=ORS=""; FS=OFS="\n"}{print $1,$2,$3; for (i=4;i<=NF;i++) printf " %s", $i; print "\n\n"}' "$basefile.cc" 
	# Remove CTRL-M's, descriptive captions enclosed in [] brackets, parenthesis and leading whitespace.
	sed -i 's/'"$(printf '\015')"'//g;s/\[[^][]*\]//g;s/([^()]*)//g;s/^[[:space:]]*//g;s/[[:space:]]*$//' "$basefile.cc"
	# Remove leading whitespace...
	# sed -i 's/^ $//g' "${title[@]%.*}.cc"
	# sed -i 's/^ *//g' "${title[@]%.*}.cc"
}

basefile="${infile[@]%.*}";
#get_subtitles
case ${infile##*.} in
		vob )
			tcextract -i "$infile" -x ps1 -t vob -a 0x20 |pv > "$basefile.ps0"; 
			infile="$basefile.ps0";
			get_subtitles
		;; 
		ps? )
			get_subtitles
		;;
		mkv )
			get_captions
		;;
		* )
			echo 'Nothing to do.';
		;;
esac;

