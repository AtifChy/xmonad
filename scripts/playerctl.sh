#!/bin/sh

set -- $(xrdb -q | grep -E "*.color0:|*.color1:|*.color2:|*.color3:|*.color4:" | cut -f2 | tr '\n' ' ')

background=$1
red=$2
green=$3
yellow=$4
blue=$5

play="playerctl play"
pause="playerctl pause"
stop="playerctl stop"

icon() {
        if [ $state = "Playing" ]; then
                printf '<action=`%s` button=3><action=`mpc play` button=2><action=%s><fc=%s,%s:5><fn=2></fn></fc></action></action></action>' \
                        "$stop" "$pause" "$green" "$background"
        elif [ $state = "Paused" ]; then
                printf '<action=`%s` button=3><action=`mpc play` button=2><action=%s><fc=%s,%s:5><fn=2></fn></fc></action></action></action>' \
                        "$stop" "$play" "$yellow" "$background"
        else
                printf '<action=mpc play><fc=%s,%s:5><fn=2></fn></fc></action>' \
                        "$red" "$background"
        fi
}

prev="<action=playerctl previous><fc=${blue},${background}:5><fn=2>玲</fn></fc></action>"
next="<action=playerctl next><fc=${blue},${background}:5><fn=2>怜</fn></fc></action>"

playerctl metadata -f '{{ status }} {{ trunc(title, 20) }} - {{ artist }}' -F |
        while read state label; do
                printf "%s %s %s %s\n" "$prev" "$(icon)" "$next" "$label"
        done
