#!/bin/bash
# Offscreen, software-only load of the XPS lock view; prints the battery label
# next to UPower's own value. Never opens a window or a GPU Quickshell.
set -euo pipefail
ulimit -c 0
here="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cp "$here/overlay/.config/omarchy/plugins/timon.lock/LockView.qml" "$tmp/"
ln -s /usr/share/omarchy/shell/Commons "$tmp/Commons"; ln -s /usr/share/omarchy/shell/Ui "$tmp/Ui"
cat >"$tmp/shell.qml" <<'QML'
import Quickshell
import QtQuick
import Quickshell.Services.UPower
ShellRoot {
  FloatingWindow { implicitWidth: 1200; implicitHeight: 800; visible: false
    LockView { id: v; anchors.fill: parent; loadBackground: false } }
  Timer { interval: 1500; running: true; onTriggered: {
    function find(it){ if (it.objectName==="lockBattery") return it; for (var i=0;i<it.children.length;i++){var r=find(it.children[i]); if(r) return r} return null }
    var b = find(v)
    console.log("BATT found=" + !!b + " visible=" + (b&&b.visible) + " text=" + (b&&b.text) + " upower=" + Math.round(UPower.displayDevice.percentage*100))
    Qt.quit() } }
}
QML
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software timeout 20 quickshell -p "$tmp" 2>&1 | grep -E "BATT|rror" || true
