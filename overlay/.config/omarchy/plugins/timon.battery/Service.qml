import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Commons
import "BatteryModel.js" as BatteryModel

// timon.battery: only the last-chance suspend countdown. At 5 % on battery a
// locked 90-second countdown appears (it can't be clicked away) and then the
// laptop suspends, so it never just dies. Plugging in cancels it.
// The low-battery warning and the AC/battery power profile switch are left to
// Omarchy's stock omarchy.battery service, which runs alongside this one.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property int countdownTriggerPercent: 5
  readonly property int countdownWindowSec: 90
  property bool countdownActive: false
  property int secondsLeft: 90
  property double countdownDeadlineMs: 0
  property int batteryLevel: -1

  function batteryPercentage() {
    return BatteryModel.batteryPercentage(UPower.displayDevice)
  }

  function isDischarging() {
    return BatteryModel.isDischarging(UPower.displayDevice, UPower.onBattery, UPowerDeviceState.Discharging)
  }

  function checkBattery() {
    batteryLevel = batteryPercentage()
    if (!isDischarging()) {
      stopCountdown()
      return
    }

    if (!BatteryModel.shouldStartCountdown(batteryLevel, countdownActive, countdownTriggerPercent))
      return

    if (!countdownActive) startCountdown()
  }

  function startCountdown() {
    countdownActive = true
    secondsLeft = countdownWindowSec
    countdownDeadlineMs = Date.now() + countdownWindowSec * 1000
    countdownTimer.running = true
  }

  function tickCountdown() {
    if (!countdownActive) {
      countdownTimer.running = false
      return
    }
    if (!isDischarging()) {
      stopCountdown()
      return
    }

    var left = Math.ceil((countdownDeadlineMs - Date.now()) / 1000)
    if (left < 0) left = 0
    secondsLeft = left
    if (left <= 0) suspendNow()
  }

  function stopCountdown() {
    countdownTimer.running = false
    countdownActive = false
    secondsLeft = countdownWindowSec
    countdownDeadlineMs = 0
  }

  function suspendNow() {
    if (suspendProcess.running) return
    countdownTimer.running = false
    countdownActive = false
    suspendProcess.command = ["systemctl", "suspend"]
    suspendProcess.running = true
  }

  Process { id: suspendProcess }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkBattery()
  }

  Timer {
    id: countdownTimer
    interval: 200
    running: false
    repeat: true
    onTriggered: root.tickCountdown()
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() { root.checkBattery() }
  }

  Connections {
    target: UPower.displayDevice
    function onPercentageChanged() { root.checkBattery() }
    function onStateChanged() { root.checkBattery() }
  }

  PanelWindow {
    id: panel
    visible: root.countdownActive
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-battery-suspend"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }

    Rectangle {
      id: card
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 72
      width: 420
      height: 160
      radius: 12
      color: Qt.rgba(0.08, 0.08, 0.08, 0.96)
      border.width: 3
      border.color: "#e24e4e"

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Column {
        anchors.centerIn: parent
        spacing: 10
        width: parent.width - 40

        Text {
          width: parent.width
          text: "Sleep in " + BatteryModel.formatCountdown(root.secondsLeft)
          font.pixelSize: 36
          font.bold: true
          color: "#e24e4e"
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          width: parent.width
          text: root.batteryLevel >= 0
            ? "Plug in now. Machine will suspend. (" + String(root.batteryLevel) + "%)"
            : "Plug in now. Machine will suspend."
          font.pixelSize: 16
          color: "#eeeeee"
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
