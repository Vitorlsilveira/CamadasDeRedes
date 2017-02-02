#!/bin/sh
ping -c 2 -I $2 $1 >/dev/null
arp -a $1
