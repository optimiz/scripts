#!/usr/bin/env bash
#  This program is free software. It comes without any warranty, to
#  the extent permitted by applicable law. You can redistribute it
#  and/or modify it under the terms of the Do What The Fuck You Want
#  To Public License, Version 2, as published by Sam Hocevar. See
#  http://sam.zoy.org/wtfpl/COPYING for more details.

# Define destination file name
dest=$1
if [ -z "$dest" ]; then
    base=scrot-`date +%Y%m%d%H%M`
    ext=png
    dest=$base.$ext
else
    base=`basename $dest | cut -d. -f1`
    ext=`echo $dest | cut -d. -f2-`
fi

# Remove tmp files
rm -fr /tmp/$base-desk*.$ext

# Save workspace count
deskn=`wmctrl -d | wc -l`
# Save workspace list
desks=`wmctrl -d | cut -d' ' -f1`
# Save current workspace
current=`wmctrl -d | grep '*' | cut -d' ' -f1`

# Iterate over workspaces
for desk in $desks; do
    # Move to such workspace
    wmctrl -s $desk
    # Take a rest (for xcompmgr/compiz animations)
    sleep 3
    # Take workspace screenshot
    # (Note: I prefer scrot because import ignores some transparency)
    tmpdest=/tmp/$base-desk$desk.$ext
    scrot $tmpdest || import -window root $tmpdest
done

# Return to last workspace
wmctrl -s $current

# Concatenate all workspace screenshots
montage -geometry +0+0 -tile 1x$deskn /tmp/$base-desk*.$ext $dest

# Create thumbnail
convert $dest -resize 256x`expr 256 \* $deskn` `echo $dest | cut -d. -f1`.thumb.$ext

# Open screenshot
thunar $dest || xdg-open $dest || gnome-open $dest || gpicview $dest || feh $dest || true >/dev/null 2>/dev/null
