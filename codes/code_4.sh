#!/usr/bin/env bash

X=$1

while getopts "p:" opt; do
  case $opt in
    p)
      X=$OPTARG
      ;;
  esac
done

if [[ "$X" ]]; then
  kill -INT "$X"
fi
