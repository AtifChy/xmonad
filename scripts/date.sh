#!/bin/sh
set -- $(
        xrdb -q |
                grep '*.background:\|*.foreground:' |
                cut -f2 |
                tr '\n' ' '
)

background=$1
foreground=$2

month=$(date '+%B %Y')
calendar() {
        today=$(date +%-d)
        cal | tail -n7 | sed "0,/$today/{s||<b><span background='${foreground}' foreground='${background}'>$today</span></b>|}"
}

dunstify -u low "$month" "$(calendar)"
