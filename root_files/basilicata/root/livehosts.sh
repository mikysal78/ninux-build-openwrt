#!/bin/bash

nmap $1 -n -sP | grep report | awk '{print $5}'

if which nmap >/dev/null; then
    nmap $1 -n -sP | grep report | awk '{print $5}'
else
    echo "devi installare nmap"
fi
