#!/bin/sh

up=$((checkupdates && paru -Qua) | wc -l)
if [[ "$up" > "1" ]]; then
	echo "$up updates"
else
	echo "$up update"
fi
