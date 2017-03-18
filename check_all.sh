#!/bin/bash

is_ip6 () {
	# TODO: replace this with posix shell
	[[ ${addr} == *:* ]]
}

uuid () {
	for file in /etc/machine-id /var/lib/dbus/machine-id /etc/hostid; do
		[ -f "$file" ] && cat "$file" && break
	done
}

now() {
	date --iso-8601=seconds
}

setup () {
	. "$(dirname $0)/config.sh"

	fetch_ip6=$(dig AAAA +short ${fetch_host} | tail -n 1)
	fetch_ip4=$(dig A +short ${fetch_host} | tail -n 1)
}

print_result () {
	test $? -eq 0 && echo 1 || echo 0
}

addresses () {
	addr=$1

	if is_ip6 ${addr}; then
		rdisc_output=${rdisc_output:-`rdisc6 -m ${device}`}
		echo "${rdisc_output}" | grep DNS | grep ${addr} 1>&2
		print_result
	else
		check_dhcp -t 30 -i $device -s $addr 1>&2
		print_result
	fi
}

dns () {
	addr=$1

	check_dns -H ${fetch_host} -s $addr 1>&2
	print_result
}

ntp () {
	# not implemented yet
	false
	print_result
}

uplink () {
	addr=$1

	if is_ip6 ${addr}; then
		ip route add ${fetch_ip6} via ${addr} dev ${device}
		curl -6 --max-time 5 --silent "http://${fetch_host}/" 1>&2
		print_result
		ip route del ${fetch_ip6} via ${addr} dev ${device}
	else
		ip route add ${fetch_ip4} via ${addr} dev ${device}
		curl -4 --max-time 5 --silent "http://${fetch_host}/" 1>&2
		print_result
		ip route del ${fetch_ip4} via ${addr} dev ${device}
	fi
}


process_host () {
	local name=$1
	local ip6=$2
	local ip4=$3
	shift; shift; shift;

cat <<EOF
	$host_sep

	{
		"name": "${name}"

EOF

	while [ $# -ne 0 ]; do

cat <<EOF
		,

		"$1": [{
		    "ipv4": `$1 ${ip4}`,
		    "ipv6": `$1 ${ip6}`
		}]

EOF
		shift;
	done

cat <<EOF
	}

EOF

	host_sep=,
}

main() {

cat <<EOF
{
	"uuid": "`uuid`",
	"name": "${name}",
	"provider": "${provider}",
	"vpn-servers": [
EOF
		process 2>/dev/null
cat <<EOF
	],

	"lastupdated": "`now`"
}
EOF

}

setup

if [ "$1" = "post" ]; then
	main 2> /dev/null | curl --max-time 5 -s -S -X POST -d @- "${api_url}?token=${token}" > /dev/null
elif [ "$1" = "verbose" ]; then
	main
else
	main 2> /dev/null
fi
