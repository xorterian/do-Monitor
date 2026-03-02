#!/usr/bin/env bash

while getopts "p:g:s:" opt; do
  case $opt in
    p)
      echo "PID $OPTARG"
      ;;
    g)
      echo "geolocation $OPTARG"
      ;;
    s)
      echo "state $OPTARG"
      ;;
  esac
done
