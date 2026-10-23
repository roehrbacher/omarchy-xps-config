# Timon's Omarchy – Dell XPS laptop

> **Heads-up:** these are my (Timon's) personal Omarchy configs and plugins, shared as-is.
> Use them at your own risk. Before installing, read the code yourself or have your
> favorite AI review it first.

## How this setup works

I run [Omarchy](https://omarchy.org) on two machines:

- **Gaming PC** – Ryzen 7 7700, Radeon RX 9060 XT
- **Laptop** – Dell XPS 14

My config is split into three repos so nothing is duplicated:

| Repo | Used on | What it holds |
|---|---|---|
| [omarchy-shared-config](https://github.com/roehrbacher/omarchy-shared-config) | both | theme, top bar layout, my plugins, keybindings, menu, night light, auto timezone, audio passthrough, Insomnia (stay awake) |
| [omarchy-pc-config](https://github.com/roehrbacher/omarchy-pc-config) | gaming PC | monitor, mouse pointer speed, headphones/speakers switching, passthrough headphones, game and streaming tweaks |
| [omarchy-xps-config](https://github.com/roehrbacher/omarchy-xps-config) | laptop | touchpad, battery and charge limit, speaker tuning, passthrough headphones, local AI model |

```
omarchy-shared-config   (install first)
        ├── omarchy-pc-config    (then this on the PC)
        └── omarchy-xps-config   (or this on the laptop)
```

**Install order:** shared first, then the machine repo. Each `install.sh` backs up
whatever it replaces, `./install.sh --dry-run` shows what would change, and
`./uninstall.sh` restores the last backup.

## What's in this repo

- **Power and battery:** watts next to the battery % in the bar, 80 % charge limit with a bar switch, last-chance
  hibernate at 4 % (notice at 15 %)
- **Touchpad:** speed, natural scrolling, three-finger gestures
- **Audio:** speaker calibrator plugin, passthrough headphones (USB-C;
  the mic is the system default)
- **Dictation:** Voxtype on the Arc B390 (Vulkan, Whisper large-v3-turbo q5_0, like the PC), held on the Copilot key
- **Apps:** Moonlight streaming window rules, local AI model for the bar toggle
- **Fonts:** bar and terminal sizes for the laptop screen

## Install

Install omarchy-shared-config first, then:

```bash
~/Work/omarchy-shared-config/install.sh
~/Work/omarchy-xps-config/install.sh
```

Backups go to `~/.local/share/omarchy-config-backups/omarchy-xps-config/`;
`./uninstall.sh` restores the latest one.

---

# Details

## Everything in here

- `hypr/machine-bindings.lua` – hold the Copilot key to dictate with Voxtype
  (F9 and the stock Copilot-key menu are unbound); middle click / three-finger
  click plays or pauses; Super+Shift+Space left unbound
- **Lid** – closing the lid suspends, on battery **and on AC**. This is
  intended (stock logind, no `HandleLidSwitchExternalPower=ignore` drop-in); to
  keep the laptop running with the lid closed, start an Insomnia session. Everything about the lid
  is generic and lives in omarchy-shared-config, which detects that this is a
  laptop (battery + lid): the lid binds and `omarchy-lid`, Insomnia in laptop
  mode (lid on battery keeps running during a session, no lock on start,
  survives unlocks, 20 % floor, tooltip "Stay awake with lid closed"), quiet
  mode while closed (`omarchy-lid-quiet`: power-saver + frozen chatty apps
  from `omarchy/lid-freeze-apps`), the 20 % low-battery power saver and
  `omarchy-power-saver` (which goes through balanced first here, because this
  XPS's two platform-profile handlers make ppd emulate power-saver). See the
  shared README.
- **80 % charge limit** – `.local/bin/battery-charge-limit [status|on|off|toggle]`
  switches UPower's charge threshold (polkit allows it for the logged-in user,
  no sudo). On: Dell *Custom* mode, charging stops at 80 % and restarts below
  75 %. Off: *Standard*, charges to 100 %. The Dell firmware stores the mode,
  so it holds through reboots, while off and in other OSes. Turned on once by
  `install.sh` (marker `~/.local/state/omarchy-config/charge-limit-default`),
  so turning it off by hand isn't undone by the next install.
  Turning it off on the charger above 80 % starts charging right away; if the
  Dell EC stays idle, the script cycles Custom -> Standard again (up to twice)
  until the battery reports Charging. `status` also prints the battery state.
- `omarchy/plugins/timon.xps-power` – the stock battery bar widget
  (`omarchy.power`, Omarchy 4.0.4) plus the charge/discharge power on the bar
  (`+12W 80%` charging, `-8W 42%` on battery, from `/sys/class/power_supply/BAT*`, every 5 s; hidden when full,
  idle, holding at the limit or under 0.5 W) and a **Limit charging to 80%** switch in
  its popup and a battery-with-heart icon on the bar while the limit is on.
  Replaces `omarchy.power` on the XPS bar (`barReplace` in `50-xps.json`).
  Re-copy `Panel.qml`/`Model.js` from `$OMARCHY_PATH/shell/plugins/panels/power/`
  and re-apply the marked changes if the stock widget ever changes a lot
- `hypr/machine-input.lua` – touchpad: slightly slower (−0.08), natural
  scrolling, clickfinger, per-app scroll speeds, three-finger swipe between
  workspaces and three-finger up/down show-desktop (`show-desktop.lua`)
- `hypr/machine-looknfeel.lua` – cursor size 20
- `hypr/machine-windows.lua` – Bitwarden, the Bitwarden web app and the Omarchy
  update terminal open tiled; loads `moonlight.lua` (Moonlight stream window
  size/opacity, no idle while streaming, tuned for the 1.6 display scale)
- `omarchy/shell.d/50-xps.json` – adds the `timon.battery` service (non-bar
  settings only; the bar, incl. `timon.xps-power`, is kept by hand in the live shell.json)
- `omarchy/plugins/timon.battery` + `.local/bin/omarchy-battery-hibernate` – vendored copy of my
  own repo [omarchy-low-battery-hibernate](https://github.com/roehrbacher/omarchy-low-battery-hibernate)
  (private; copy of `d3bed95`, tests there). Update: change it there, copy the files here.
  Low-battery steps on battery: a gentle notice at
  **15 %**, Omarchy's stock warning at 10 %, then at **4 %** a 60-second countdown you
  can't click away ("Hibernating to save your work. Plug in to cancel.", with a
  *Hibernate now* button) in a flat Omarchy-style card in the theme's urgent colour.
  At 0 it runs `.local/bin/omarchy-battery-hibernate`: lock, end Insomnia, hibernate
  (suspend if hibernate fails); you resume at the lock screen. Plugging in cancels.
  It also runs with the lid closed during an Insomnia session (Insomnia no longer ends
  at 20 %, this is its safety net); while ending Insomnia it holds the lid switch itself
  so logind can't suspend first.
  4 % is ~2.7 Wh; countdown + hibernate need ~0.5 Wh.
  **Old or worn battery?** 4 % is tuned for a new battery. Near empty, an aged
  battery's percentage gets unreliable and it can cut out early, so raise
  `countdownTriggerPercent` in `Service.qml` to 6-8 %. Preview without hibernating:
  `omarchy-shell timon.battery preview`. The AC/battery power-profile switch comes from
  Omarchy's stock `omarchy.battery` service.
  While charging it sends one **"Fully charged – you can unplug the charger"** notification
  at **80 %** (`fullChargeNoticePercent` in `Service.qml`, matching the 80 % charge limit).
  It fires once per plugged-in session; unplugging, or dropping below 75 %
  (`fullChargeRearmPercent`), re-arms it. Test: `omarchy-shell timon.battery testFullChargeNotice`
- `omarchy/plugins/thefreshoffice.speaker-calibrator` 1.2.0 – installed, not on the bar.
  Reviewed copy of github.com/thefreshoffice/omarchy-speaker-calibrator at `b142b02`
  (commit in `.upstream-commit`, listed in `plugins.lock`). The optional shared-calibration
  registry (GitHub) is off until you allow it in the panel; Share only sends after a second press.
  The XPS speakers are calibrated (sink `omarchy_speaker_tuning`, the default
  output); the calibrator keeps its tuning in `~/.config/pipewire/` and its own
  data folders, which this repo does not track. The shared `timon.audio` panel
  shows that sink as the Speakers row
- `omarchy/local-ai.json` – models for the shared `timon.local-ai` bar plugin:
  Qwen3.6 35B-A3B (`llama-qwen.service`, health check on port 8080). The unit
  itself is set up by hand (model under `~/Models`), stays disabled, and is only
  started from the bar
- `omarchy/shell.toml` – bar font size 11
- `systemd/user/voxtype.service.d/gpu.conf` – runs the Vulkan build of Voxtype on the Arc B390
  (logs each dictation; replaced the old Parakeet `onnx-avx2.conf`, removed by install)
- Voxtype settings (`voxtype/config.toml`) come from omarchy-shared-config (same on
  both machines). Only the drop-in above is XPS-specific (Vulkan build on the Arc,
  `--flash-attention`). About 1.8 s per 6–7 s dictation on battery/power-saver
  (Parakeet was ~0.7 s but ignored the vocabulary hint). Switch back to Parakeet:
  `voxtype-onnx-avx2 --engine parakeet daemon` in gpu.conf
- `alacritty`, `ghostty`, `kitty` configs – terminal font size 8

`install.sh` also removes the old misnamed `voxtype.service.d/vulkan.conf`
(it forced onnx-avx2 too), the old `omarchy-xps-lid` (now the shared
`omarchy-lid`) and the old managed `omarchy/insomnia.conf` (Insomnia now detects
the laptop itself; a hand-made `insomnia.conf` override is left alone).

## Set by hand (not in this repo)

- **Phone hotspot fallback** – a saved phone-hotspot Wi-Fi gets a lower
  autoconnect priority than every other saved network, so the laptop only joins
  it when nothing better is around. Set it with
  `nmcli connection modify "<hotspot-name>" connection.autoconnect yes connection.autoconnect-priority -10`.

## Root files

None any more. The old logind lid-on-AC drop-in was dropped in favour of
Insomnia; `install.sh` reminds you to delete it if it is still installed.

## Not here on purpose

`monitors.lua` and `dell-haptic.conf` are stock Omarchy on this laptop, the
default agent is set by hand.

## Packages

Laptop-only extra apps (`PACKAGES` in `repo.conf`; the shared list is in omarchy-shared-config): snapshot. The custom kernel (linux-ptl) is left out on purpose.

`./install.sh` installs only the ones that are missing (`pacman -S --needed`,
AUR packages through `yay`). It never upgrades or removes anything, and a package
that fails is skipped with a message. If sudo needs a password and there is no
terminal, it just prints what is pending. `./uninstall.sh` never removes packages;
remove them by hand with `sudo pacman -Rns <pkg>`.

**Using this repo yourself?** Trim `PACKAGES` in `repo.conf` to the apps you want first.

## License

0BSD (see `LICENSE`), © 2026 Timon Röhrbacher. Third-party plugins and assets in `overlay/` (e.g. folders not named `timon.*`) keep their own licenses, see the `LICENSE` file inside each.

## Plugin updates

External plugins are pinned in `plugins.lock` (this repo, XPS-only) and in
`omarchy-shared-config/plugins.lock` (both machines). The weekly plugin round checks
every entry in both files against upstream, reviews the full diff, and updates the
copy only when it is safe.

## Auto Brightness

`timon.auto-brightness` (own private repo github.com/roehrbacher/omarchy-auto-brightness, MIT)
drives the screen and keyboard light from the XPS's two ambient light sensors
(iio `als`, raw × scale), no camera. `install.sh` clones it into the plugins
folder and runs its installer (user service `omarchy-auto-brightness`);
`50-xps.json` puts its icon after the display widget. Settings:
`~/.config/omarchy/auto-brightness.json` or the bar popup.
