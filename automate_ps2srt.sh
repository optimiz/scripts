#! /bin/bash
# Thursday, February 04 2016 - FE - Automate DVD private stream (PS) subtitle conversion to SRT.
# tcextract -i "$title.vob" -x ps1 -t vob -a 0x20 |pv > "$title.ps0"

if [ -e "$1" ]; then infile="$1"
	else echo "Specify PS file to convert on command line." && exit 1;
fi;
tmpdir=$(mktemp -d) || exit 1
basefile="${infile[@]%.*}";
#trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
cp "$infile" "$tmpdir"
pushd "$tmpdir"

# Convert PS to IDX/SUB for BDSup2Sub
subtitle2vobsub -p "$infile" -o "$basefile"
# Convert PS to SRTX/PGM for srttool and graphicsmagick; NOTE: This tool outputs correct timing, but incorrect frames (doubles, missing, etc.)
subtitle2pgm -P -i "$infile" -o "$basefile"
# Convert IDX/SUB to XML/PNG; NOTE: This tool outputs correct frames; unfortunately, this tool doesn't support PS directly.
java -jar BDSup2Sub.jar -o "$basefile.xml" "$basefile.idx"

# Prepare PNG frames for OCR -- tesseract (leptonica) doesn't properly detect characters without processing -- due to transparency??
# NOTE: Graphicsmagick v1.3.20 doesn't support flatten option with mogrify option, convert to separate file instead.

# Replace "for loop" with moreutils-parallel (not GNU parallel); processes faster than "for loop".
# for pics in "$infile"*.png; do subs="$pics.pgm"; gm convert "$pics" -contrast -fuzz 10% -transparent grey -flatten "$subs"; tesseract "$subs" "$subs"; done

parallel -i gm convert {} -contrast -fuzz 10% -transparent grey -flatten {}.pgm -- "$basefile"*.png
parallel -i tesseract {} {} -- "$basefile"*.png.pgm 

# Modify the SRTX to refer to the OCR output from the processed frames.
sed -i "s/$basefile/$basefile\_/g;s/pgm/png.pgm/g" "$basefile.srtx"
# Convert SRTX/OCR'd text to SRT for further manipulation in a subtitle editor.
srttool -s -i "$basefile.srtx" -o "$basefile.srt" 
# tmpdir is deleted on exit trap, no need for manual remove.
# rm "$infile"*.{png,pgm,idx,xml,srtx,txt,sub}

popd
# mv  "$tmpdir/$infile.srt" "${infile[@]%.*}.srt"
# awk '!NF{print}/[a-z]/{printf "%s ", $0;next}1' "$tmpdir/$infile.srt" > "${infile[@]%.*}.srt"
# Remove word wrap on subtitles; most player subtitle decoders perform sentence and word-wraping automatically and admirably.
awk 'BEGIN {RS=ORS=""; FS=OFS="\n"}{print $1,$2,$3; for (i=4;i<=NF;i++) printf " %s", $i; print "\n\n"}' "$tmpdir/$basefile.srt" > "$basefile.srt"

# aspell -d en -c "${infile[@]%.*}.srt"

# Extract closed captioning EIA-608 and convert to SRT
# ffmpeg -f lavfi -i "movie=$title.vob[out0+subcc]" -map s "${title[@]%.*}.cc"
# awk 'BEGIN {RS=ORS=""; FS=OFS="\n"}{print $1,$2,$3; for (i=4;i<=NF;i++) printf " %s", $i; print "\n\n"}' "${title[@]%.*}.cc" |sed 's/^M//g' > "${infile[@]%.*}.srt"
