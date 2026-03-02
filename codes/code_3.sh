#!/usr/bin/env bash

VARS="vars.ini"
MODE=$1
X=""
case $2 in
    '1') X="TARGET";;
    '2') X="IS_GEOLOG";;
    '3') X="DT";;
    '4') X="IS_USSD";;
    '5') X="USSD_PRIME";;
    '6') X="IS_REC";;
esac

while read line; do
    if [[ "$line" != "[vars]" ]]; then
        eval "$line"
    fi
done < "$VARS"

if [[ "$MODE" == "2" ]]; then
    echo "The variable $X is $(eval echo "\$$X")."
elif [[ "$MODE" == "1" ]]; then
    if [[ "$3" ]]; then
        eval "$(eval echo "\$X")=$3"
        echo "The variable $X is changed to $(eval echo "\$$X")."
    else
        eval "$(eval echo "\$X")=1"
        echo "The variable $X is ON."
    fi
else
    eval "$(eval echo "\$X")=0"
    echo "The variable $X is OFF."
fi

rm "$VARS"
echo "[vars]" >> "$VARS"
echo "TARGET=$TARGET" >> "$VARS"
echo "IS_GEOLOG=$IS_GEOLOG" >> "$VARS"
echo "DT=$DT" >> "$VARS"
echo "IS_USSD=$IS_USSD" >> "$VARS"
echo "USSD_PRIME=$USSD_PRIME" >> "$VARS"
echo "IS_REC=$IS_REC" >> "$VARS"

