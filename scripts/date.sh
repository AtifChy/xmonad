#!/bin/sh
month=$(date '+%B %Y')
calendar() {
        today=$(date +%d)
        cal | tail -n7 | sed "s|$today|<u><b>$today</b></u>|"
}

dunstify -u low "$month" "$(calendar)"
