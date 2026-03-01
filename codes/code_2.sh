#!/usr/bin/env bash

ARG=$1
MODE=$2
C="Failed!"
case "$MODE" in
    1)
        python3 code_2.py "$ARG" "1" "$MODE"
        C="Done!" ;;
    0)
        python3 code_2.py "$ARG" "-1" "$MODE"
        C="Done!" ;;
    2)
        C=$(python3 code_2.py "$ARG" "$MODE") ;;
esac

echo "$C"

