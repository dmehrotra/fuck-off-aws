#!/bin/bash
pfctl -e
ifconfig pflog0 create
tcpdump -n -e -ttt -i pflog0
trap '{ echo "Stop blocking traffic to aws" ; pfctl -d
; exit 1; }' INT
