# tailscaled-vpn

Turn a Tailscale exit node on and off from the command line on a Mac that runs
the open-source `tailscaled` (for example from Homebrew), which has no app or
menu bar item. Useful on public Wi-Fi: your internet traffic leaves from a
machine you own instead.

You probably don't need this if you use the Tailscale app for macOS.

## Why not just `tailscale set --exit-node`?

With open-source `tailscaled` on macOS (seen on 1.96.4; 1.104.7 has the same
routing code), that command alone does not protect you:

- **IPv4 isn't tunneled.** `tailscaled` tries to add a second default route,
  which fails because your network already has one. Turning the exit node off then
  deletes the network's default route and you lose internet.
- **DNS leaks.** It can't replace the main DNS server, so lookups still go to
  the local network's.

`vpn on` routes `0.0.0.0/1`, `128.0.0.0/1` and the IPv6 equivalents into the
tunnel, keeps a default route scoped to your network interface so Tailscale's
own packets don't loop, and points DNS at Tailscale's resolver. `vpn off` removes
the routes and restores your DNS settings.

## Requirements

- macOS with `tailscaled` running and signed in
- `jq` (`brew install jq`)
- An admin account: `on` and `off` use `sudo` to change routes
- Another machine in your tailnet to act as the exit node

## Setup

1. On the exit node, offer it (Linux also needs
   [IP forwarding](https://tailscale.com/docs/features/exit-nodes)):

   ```bash
   tailscale set --advertise-exit-node
   ```

2. On the [Machines page](https://console.tailscale.com/admin/machines), open the
   machine's menu, choose **Edit route settings**, and turn on **Use as exit node**.

3. On this Mac, create your settings file and put the exit node's Tailscale
   IPv4 address (from `tailscale status`) in it:

   ```bash
   cp .env.example .env
   ```

   `.env` is ignored by git. Environment variables of the same name override it.

## Use

```bash
./vpn on
```

```bash
./vpn off
```

```bash
./vpn status
```

`on` only reports success if sample IPv4 and IPv6 addresses are routed into the
tunnel, every network service uses Tailscale's DNS, and the internet is
reachable; otherwise it undoes its changes. If the VPN was already on,
it warns and leaves it on.
`status` exits 0 if protecting, 3 if off, 1 otherwise. `on` and `status` contact
api.ipify.org to check your public IP. To run `vpn` from anywhere,
symlink it into a directory on your `PATH`.

`status --local` skips the public IP check and contacts nothing.

`./test-vpn.sh` turns the VPN on, checks it and turns it off again. It briefly
interrupts your connection.

## Menu bar indicator (optional)

1. Install [SwiftBar](https://github.com/swiftbar/SwiftBar):
   `brew install --cask swiftbar`.
2. Open it and choose any folder for your plugins, such as `~/SwiftBar`. SwiftBar
   uses one plugin folder, so don't choose this project's.
3. From this project's folder, link the plugin into it:

   ```bash
   ln -s "$PWD/swiftbar/vpn.10s.sh" ~/SwiftBar/
   ```

   If you move or rename this project, replace the link.

A green filled shield means on, a grey open lock means off, and a red warning
shield means something needs attention. It refreshes every 10 seconds using
`vpn status --local`, so green doesn't prove the internet is reachable. Click it
for **Turn on** and **Turn off**, which open a terminal for your password. You
can close that window once the command finishes; closing it during `on` interrupts it.

## Limits

- **Sign-in Wi-Fi:** finish the hotel or café sign-in page before `vpn on`.
- **Changing networks or plugging in a dock or phone:** run `vpn off`
  first and `vpn on` after. Network changes, sleep and reboot while on are untested; check `vpn status` afterwards.
- **Lost internet:** run `vpn off`. If that doesn't help, reconnect your
  network (turn Wi-Fi off and on, or unplug and replug the cable).
- **Hostile networks:** a malicious network can route public addresses around the
  VPN (the TunnelVision and TunnelCrack attacks). `on` refuses to start on such a
  network, and `status` warns if it happens later, but nothing blocks the traffic
  meanwhile. Not detected: an IPv6 `/64` claimed as local, because normal networks
  do that too, and forged neighbor entries. Networks that use public addresses
  internally, as some universities do, are refused too.
- **Open connections:** apps already connected, or bound to a specific network
  interface, may bypass the tunnel. Restart sensitive apps after `vpn on`.
- **Previous settings:** `vpn off` doesn't restore a different exit node or the
  allow-LAN-access setting, and DNS manually set to 100.100.100.100 becomes
  automatic.
- **Not a full kill switch:** if `tailscaled` stops, traffic can go out unprotected.
- **Exit node power:** a Mac with FileVault won't run Tailscale after a restart
  until someone unlocks it.
