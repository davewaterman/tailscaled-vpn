#!/bin/bash
# Turns the VPN on, checks it, turns it off again. Interrupts networking briefly.
# Start with the VPN off.
cd "$(dirname "$0")" || exit 1
fails=0
check() { if "${@:2}"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }
routes() { netstat -rnf inet | awk '($1=="default" && $4 !~ /^utun/) || $1 ~ /^(0\/1|128(\.0)?\/1)$/ {print $1, $2, $4}'; }
dns() { networksetup -listallnetworkservices | awk 'NR>1 {sub(/^\*/, ""); print}' | while IFS= read -r s; do echo "$s"; networksetup -getdnsservers "$s"; done; }
same() { [[ $1 == "$2" ]] || { echo "  before: $1"; echo "  after:  $2"; return 1; }; }
https() { curl -sf -o /dev/null -m 20 https://www.apple.com; }
resolves() { [[ -n $(dscacheutil -q host -a name example.com) ]]; }
in_tunnel() { [[ $(route -n get 1.1.1.1 | awk '/interface:/{print $2}') == utun* ]]; }

./vpn status; [[ $? == 3 ]] || { echo "Turn the VPN off first."; exit 1; }
sudo -v || exit 1
routes0=$(routes); dns0=$(dns)
trap './vpn off; exit 1' INT TERM HUP

check "on" ./vpn on
check "IPv4 enters the tunnel" in_tunnel
check "DNS resolves" resolves
check "HTTPS works" https
check "on again" ./vpn on
check "off" ./vpn off
check "routes restored" same "$routes0" "$(routes)"
check "DNS settings restored" same "$dns0" "$(dns)"
check "HTTPS works when off" https
check "off again" ./vpn off
check "routes unchanged" same "$routes0" "$(routes)"
echo "TEST-DONE: $fails failed"
[[ $fails == 0 ]]
