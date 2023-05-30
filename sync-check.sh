#! /bin/bash

# Fetch hash of latest commit of the uploaded PDF
URL='https://perso.crans.org/vanille/share/satge/arpe/'
HASH="$( curl "$URL/rfmig.hash" 2>/dev/null )"
TIME="$( curl "$URL/rfmig.time" 2>/dev/null )"
echo "$HASH"
echo "$TIME"

# Fetch all commits since
COUNT="$( git log |
    grep -E 'commit [a-f0-9]+' |
    sed -n "0,/$HASH/p" |
    wc -l
)"
let 'COUNT -= 1'
echo "$COUNT"

if [ $COUNT = 0 ]; then
    BADGE="https://img.shields.io/badge/Updated-$TIME-green"
else
    BADGE="https://img.shields.io/badge/Behind-$COUNT%20commits-red"
fi
curl "$BADGE" > badge.svg
