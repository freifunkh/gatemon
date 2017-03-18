# Installation

``` shell
apt-get install monitoring-plugins-basic monitoring-plugins-standard \
                nagios-plugins-contrib ndisc6 dnsutils
git clone https://github.com/freifunkh/gatemon /usr/lib/gatemon
cd /usr/lib/gatemon/cron
make check_dhcp
cp cron /etc/cron.d/gatemon_check_all
```

Edit the configuration `/usr/lib/gatemon/config.sh`:

``` shell
#!/bin/sh

# general config
device=bat0                          # interface which to use
fetch_host='meineip.moritzrudert.de' # http and dns test host - should be reachable via v4 and v6
name="hans"                          # human readable name for the test host
provider="HETZNER"                   # provider information


# this data is needed to push to the master
token=Goola4Ma
api_url=http://harvester.ffh.zone/put.php


# this function will be called to test all hosts

process() {
        for i in $(seq 9); do
                # sn06 is not existing yet :)
                if [ $i -eq 6 ]; then
                        continue;
                fi

                # process host $name $ip6 $ip4 test1 test2 ...
                process_host sn0${i}.s.ffh.zone fdca:ffee:8::${i}001 10.2.${i}0.1 \
	       		addresses dns uplink
        done
}
```

