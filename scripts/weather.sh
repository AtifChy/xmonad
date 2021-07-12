#!/bin/sh
weather=$(curl -s wttr.in/?format="%C+%t\n")

condition=${weather% *}
temperature=${weather##* }

hour=$(date +%H)
night_yet() {
        [ "$hour" -ge 20 ] && icon=$*
        [ "$hour" -le 4 ] && icon=$*
}

case $condition in
        "Unknown") icon=" " ;;
        "Cloudy") icon=" " ;;
        "Fog" | "Mist")
                icon=" "
                night_yet " "
                ;;
        "Heavy rain") icon=" " ;;
        "Heavy showers") icon=" " ;;
        "Heavy snow") icon=" " ;;
        "Heavy snow showers") icon=" " ;;
        "Light rain")
                icon=" "
                night_yet " "
                ;;
        "Light showers")
                icon=" "
                night_yet " "
                ;;
        "Light sleet")
                icon=" "
                night_yet " "
                ;;
        "Light sleet showers")
                icon=" "
                night_yet " "
                ;;
        "Light snow")
                icon=" "
                night_yet " "
                ;;
        "Light snow showers")
                icon=" "
                night_yet " "
                ;;
        "Partly cloudy")
                icon=" "
                night_yet " "
                ;;
        "Sunny")
                icon=" "
                night_yet ""
                ;;
        "Thundery heavy rain") icon=" " ;;
        "Thundery showers") icon=" " ;;
        "Thundery snow showers")
                icon=" "
                night_yet " "
                ;;
        "Very cloudy") icon=" " ;;
        *) icon=$condition ;;
esac

case $1 in
        bar) printf '%b' "<fc=#ffcb6b,#2c313a:5>${icon} </fc><fc=#a6aebf,#2c313a:5>${temperature}</fc>" ;;
        *) printf '%b' "${icon} ${temperature}" ;;
esac
