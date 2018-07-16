#!/bin/bash

POSITION=1
FILTERS=""
JSON_URL="https://ip-ranges.amazonaws.com/ip-ranges.json"

function extract_ip_ranges() {
    local json=$1
    local filters=$2
    local array=$3
    local prefix=$4

    local group='group_by(.'$prefix')'
    local map='map({ "ip": .[0].'$prefix', "regions": map(.region) | unique, "services": map(.service) | unique })'

    local to_string='.ip + " \"" + (.regions | sort | join (", ")) + "\" \"" + (.services | sort | join (", ")) + "\""'
    local process='[ .'$array"[]$filters ] | $group | $map | .[] | $to_string"

    local ranges=$(echo "$json" | jq -r "$process" | sort -Vu)
    echo "$ranges"
}

function add_pf_rules() {

    local lines
    local data

    IFS=$'\n' lines=($2)
    unset IFS

    for line in "${lines[@]}"; do
        eval local data=($line)
        local ip=${data[0]}
        pfctl -t aws -T add "$ip"
    done
}

if [ ! -t 0 ]; then
    JSON=$(cat - <&0)
else
    JSON=$(curl -s -L $JSON_URL)
fi




V4_RANGES=$(extract_ip_ranges "$JSON" "$FILTERS" "prefixes" "ip_prefix")
add_pf_rules ""  "$V4_RANGES"
V6_RANGES=$(extract_ip_ranges "$JSON" "$FILTERS" "ipv6_prefixes" "ipv6_prefix")
add_pf_rules "6"  "$V6_RANGES"
