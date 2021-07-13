#!/bin/sh
weather=$(curl -s wttr.in/?format="%x+%t\n")
[ -z "$weather" ] && exit 1
condition=${weather% *}
temperature=${weather##* }

hour=$(date +%H)
night_yet() {
        [ "$hour" -ge 19 ] && icon=$*
        [ "$hour" -le 4 ] && icon=$*
}

case $condition in
        "?") icon="" ;;
        "mm") icon="" ;;
        "=" )
                icon=""
                night_yet ""
                ;;
        "///") icon="" ;;
        "//") icon="" ;;
        "**") icon="" ;;
        "*/*") icon="" ;;
        "/")
                icon=""
                night_yet ""
                ;;
        ".")
                icon=""
                night_yet ""
                ;;
        "x")
                icon=""
                night_yet ""
                ;;
        "x/")
                icon=""
                night_yet ""
                ;;
        "*")
                icon=""
                night_yet ""
                ;;
        "*/")
                icon=""
                night_yet ""
                ;;
        "m")
                icon=""
                night_yet ""
                ;;
        "o")
                icon=""
                night_yet ""
                ;;
        "/!/") icon="" ;;
        "!/") icon="" ;;
        "*!*")
                icon=""
                night_yet ""
                ;;
        "mmm") icon="" ;;
        *) icon=$condition ;;
esac

case $1 in
        bar) printf "<fc=#ffcb6b,#2c313a:5>%s</fc><fc=#a6aebf,#2c313a:5> %s</fc>\n" \
                "$icon" "$temperature" ;;
        *) printf "%s  %s\n" "$icon" "$temperature" ;;
esac
