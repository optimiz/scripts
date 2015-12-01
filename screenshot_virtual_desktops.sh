#! /usr/bin/bash
#  This program is free software. It comes without any warranty, to
#  the extent permitted by applicable law. You can redistribute it
#  and/or modify it under the terms of the Do What The Fuck You Want
#  To Public License, Version 2, as published by Sam Hocevar. See
#  http://sam.zoy.org/wtfpl/COPYING for more details.

function toggle_window {
	for each in $terminals; do
		wmctrl -r $each -i -b toggle,below;
	done
}

# Define destination file name
dest=$1
if [ -z "$dest" ]; then
    base=screenshot-$(date +%Y%m%d%H%M)
    ext=png
    dest=$base.$ext
else
    base=$(basename $dest | cut -d. -f1)
    ext=$(echo -n $dest | cut -d. -f2)
fi

terminals=$(wmctrl -lp |grep $(ps -u $(whoami) |grep mate-terminal |cut -d' ' -f1) | cut -c-10)
# Only count workspaces with active windows, not empty desktops.
desktops=$(wmctrl -l | cut -c13 | sort -u | wc -l)
# Send terminal window(s) behind others.
toggle_window

if [ "$desktops" -eq "1" ]; then
	scrot $dest || gm import -window root $dest;
	toggle_window;
	exit 0;
else
# Make temp dir, clear contents on exit.
	tmpdir=$(mktemp -d) || exit 1
	trap 'rm -rf "$tmpdir"' EXIT INT TERM HUP
	workspaces=$(wmctrl -l | cut -c13 | sort -u)
	# Save current workspace
	current=$(wmctrl -d | grep '*' | cut -d' ' -f1)
	# Iterate over workspaces
	for each in $workspaces; do
		# Switch to workspace
		wmctrl -s $each
		# Pause for screen layout (xcompmgr/compiz animations) to complete
		sleep 1.25
		# Take workspace screenshot
		# (Note: Prefer scrot; import ignores some transparency)
		tmpdest=$tmpdir/$base-ws$each.$ext
		scrot $tmpdest || import -window root $tmpdest
	done

# Return to original workspace and bring terminal window(s) back.
	wmctrl -s $current
	toggle_window

# Tile as square/rectangular collage; use graphicsmagick instead of imagemagick; output as lossless JPEG 2000.
	grid=$(($desktops/2+$desktops%2))
	gm montage -geometry +0+0 -tile "$grid"x"$grid" $tmpdir/$base-ws*.$ext -compress lossless $base.jp2

fi
