#! /bin/bash
# Thursday, February 04 2016 - FE - Automate DVD private stream (PS) subtitle conversion to SRT.

infile="$1"
tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
cp "$infile" "$tmpdir"
pushd "$tmpdir"

# Convert PS to IDX/SUB for BDSup2Sub
subtitle2vobsub -p "$infile" -o "$infile"
# Convert PS to SRTX/PGM for srttool and graphicsmagick; NOTE: This tool outputs correct timing, but incorrect frames (doubles, missing, etc.)
subtitle2pgm -P -i "$infile" -o "$infile"
# Convert IDX/SUB to XML/PNG; NOTE: This tool outputs correct frames; unfortunately, this tool doesn't support PS directly.
java -jar BDSup2Sub.jar -o "$infile.xml" "$infile.idx"

# Prepare PNG frames for OCR -- tesseract (leptonica) doesn't properly detect characters without processing -- due to transparency??
# NOTE: Graphicsmagick v1.3.20 doesn't support flatten option with mogrify option, convert to separate file instead.

# Replace "for loop" with moreutils-parallel (not GNU parallel) for concurrent (and faster) processing.
# for pics in "$infile"*.png; do subs="$pics.pgm"; gm convert "$pics" -contrast -fuzz 10% -transparent grey -flatten "$subs"; tesseract "$subs" "$subs"; done

parallel -i gm convert {} -contrast -fuzz 10% -transparent grey -flatten {}.pgm -- "$infile"*.png
parallel -i tesseract {} {} -- "$infile"*.png.pgm

# Modify the SRTX to refer to the OCR output from the processed frames.
sed -i "s/$infile/$infile\_/g;s/pgm/png.pgm/g" "$infile.srtx"
# Convert SRTX/OCR'd text to SRT for further manipulation in a subtitle editor.
srttool -s -i "$infile.srtx" -o "$infile.srt" 
# tmpdir is deleted on exit trap, no need for manual remove.
# rm "$infile"*.{png,pgm,idx,xml,srtx,txt,sub}

popd
mv  "$tmpdir/$infile.srt" "${infile[@]%.*}.srt"

