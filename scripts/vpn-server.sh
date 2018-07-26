#!/bin/bash -e

# from https://github.com/corbanworks/aws-blocker/blob/master/aws-blocker

POSITION=1
FILTERS=""
JSON_URL="https://ip-ranges.amazonaws.com/ip-ranges.json"

if [[ -n $1 ]]; then
    POSITION=$1
    shift
fi


function build_filters() {
    for arg in ${@:1}; do
        if [[ -n $filters ]]; then
            filters=$filters", "
        fi

        filters=$filters"select(.region | contains(\"$arg\"))"
    done

    if [[ -n $filters ]]; then
        filters=" | "$filters
    fi

    echo $filters
}


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


function create_and_flush_chain() {
    local version=$1
    local position=$2
    local cmd=ip${version}tables

    $cmd -n --list AWS >/dev/null 2>&1 \
        || ($cmd -N AWS && $cmd -I INPUT $position -j AWS)

    $cmd -F AWS
}



function add_iptables_rules() {
    local version=$1
    local cmd=ip${version}tables
    local lines
    local data

    IFS=$'\n' lines=($2)
    unset IFS

    for line in "${lines[@]}"; do
        eval local data=($line)
        local ip=${data[0]}
        local regions=$(echo ${data[1]} | tr '[:upper:]' '[:lower:]')
        local services=$(echo ${data[2]} | tr '[:upper:]' '[:lower:]')
        $cmd -I FORWARD 1 -i tun0 -d "$ip" -j REJECT
    done
}


if [ ! -t 0 ]; then
    JSON=$(cat - <&0)
else
    JSON=$(curl -s -L $JSON_URL)
fi

FILTERS=$(build_filters "$*")


# IPv4
create_and_flush_chain "" $position
echo "v4"
V4_RANGES=$(extract_ip_ranges "$JSON" "$FILTERS" "prefixes" "ip_prefix")
add_iptables_rules ""  "$V4_RANGES"


# IPv6
create_and_flush_chain 6 $position
V6_RANGES=$(extract_ip_ranges "$JSON" "$FILTERS" "ipv6_prefixes" "ipv6_prefix")
add_iptables_rules "6" "$V6_RANGES"