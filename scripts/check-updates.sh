#!/bin/sh
checkupdates | wc -l

#while :; do
#        timeout 10 tail -F /var/log/pacman.log |
#                grep --line-buffered -e 'upgraded\|installed\|removed' |
#                head -n1 |
#                while read -r _; do
#                        checkupdates | wc -l
#                done
#done
