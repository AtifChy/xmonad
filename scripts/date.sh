#!/bin/sh
month=$(date '+%B %Y')
calendar() {
        today=$(date +%-d)
        cal | tail -n7 | sed "0,/$today/{s||<u><b>$today</b></u>|}"
}

dunstify -u low "$month" "$(calendar)"
