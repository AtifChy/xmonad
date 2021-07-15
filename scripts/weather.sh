#!/bin/sh
for i in 1 2 3; do
        weather=$(curl -s wttr.in/?format="%x+%t\n") && break || sleep 2s
done
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
        "=")
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
        bar)
                set -- $(xrdb -q | grep -E '*.color0:|*.color3:|*.color7:' | cut -f2 | tr '\n' ' ')

                background=$1
                yellow=$2
                white=$3

                printf '<fc=%s,%s:5>%s</fc><fc=%s,%s:5> %s</fc>\n' \
                        "$yellow" "$background" "$icon" "$white" "$background" "$temperature"
                ;;
        *) printf "%s  %s\n" "$icon" "$temperature" ;;
esac
