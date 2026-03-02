#!/usr/bin/env bash

MODE=$1
ARG=$2
C="You switch the program"
case "$MODE" in
    1)
        C="$C on" ;;
    0)
        C="$C off" ;;
    2)
        C="You asked if the program is on" ;;
esac

C="$C with argument $ARG."

echo "$C"

