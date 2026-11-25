#!/bin/bash
# SwiftBar plugin: shows whether the VPN is on, with on/off menu items.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
self=$0
while [[ -L $self ]]; do
  link=$(readlink "$self")
  [[ $link == /* ]] || link="$(dirname "$self")/$link"
  self=$link
done
vpn="$(cd "$(dirname "$self")/.." && pwd)/vpn"

out=$("$vpn" status --local 2>&1)
case $? in
  0) echo "| sfimage=checkmark.shield.fill sfcolor=#34C759" ;;
  3) echo "| sfimage=lock.open sfcolor=#8E8E93" ;;
  *) echo "| sfimage=exclamationmark.shield.fill sfcolor=#FF3B30" ;;
esac
echo "---"
echo "${out//|/ }"
echo "---"
echo "Turn on | bash='$vpn' param1=on terminal=true refresh=true"
echo "Turn off | bash='$vpn' param1=off terminal=true refresh=true"
echo "Refresh | refresh=true"
