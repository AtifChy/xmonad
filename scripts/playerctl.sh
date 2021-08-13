#!/bin/sh

set -- $(xrdb -q | grep -E '*.color0:|*.color2:|*.color3:|*.color4:' | cut -f2 | tr '\n' ' ')

background=$1
green=$2
yellow=$3
blue=$4

play="playerctl play"
pause="playerctl pause"
stop="playerctl stop"
song="playerctl -a pause && playerctl --player=mpd play"

icon() {
        if [ "${_status}" = "Playing" ]; then
                printf '<action=`%s` button=3><action=`%s` button=2><action=%s><fc=%s,%s:5><fn=2></fn></fc></action></action></action>' \
                        "$stop" "$song" "$pause" "$yellow" "$background"
        else
                printf '<action=`%s` button=3><action=`%s` button=2><action=%s><fc=%s,%s:5><fn=2></fn></fc></action></action></action>' \
                        "$stop" "$song" "$play" "$green" "$background"
        fi
}

prev="<action=playerctl previous><fc=${blue},${background}:5><fn=2>玲</fn></fc></action>"
next="<action=playerctl next><fc=${blue},${background}:5><fn=2>怜</fn></fc></action>"

playerctl metadata -f '{{ status }}' -F |
        while read -r _status; do
                printf "%s %s %s\n" "$prev" "$(icon)" "$next"
        done
