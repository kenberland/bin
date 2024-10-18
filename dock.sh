xrandr --output eDP-1 --off --output DP-3 --auto
xinput set-prop 'PixArt Microsoft USB Optical Mouse' "libinput Scroll Method Enabled" 0 0 1
xinput set-prop 'PixArt Microsoft USB Optical Mouse' "libinput Button Scrolling Button" 3
xfconf-query -c xsettings -p /Xft/DPI -s 112
