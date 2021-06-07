#!/usr/bin/env sh

up=$($(
        checkupdates &
        paru -Qua
) | wc -l)
if [ "$up" -gt "1" ]; then
        echo "$up updates"
else
        echo "$up update"
fi
