import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import qs.Commons
import "BatteryModel.js" as BatteryModel

// timon.battery: low-battery steps on top of Omarchy's stock 10 % warning.
//   15 %  a gentle notification (once per discharge)
//    5 %  a locked 60-second countdown (it can't be clicked away, "Hibernate now"
//         skips the wait), then omarchy-battery-hibernate: lock, end Insomnia,
//         hibernate (suspend if that fails). Plugging in cancels it.
// 5 % of 68.6 Wh is ~3.4 Wh. The 60 s countdown (~7-15 W, <=0.25 Wh) plus the
// hibernate itself (image capped at 13.2 GB, compressed to ~5-7 GB, written to
// the encrypted NVMe in well under a minute at ~20 W, ~0.3 Wh) need ~0.5 Wh,
// so 5 % leaves ~6x margin; even at 40 W load 3.4 Wh last ~5 min, and the
// battery is new (full = design capacity), so the gauge is still accurate.
// Preview (never hibernates): omarchy-shell timon.battery preview  (stop: cancelPreview)
// The low-battery warning and the AC/battery power profile switch are left to
// Omarchy's stock omarchy.battery service, which runs alongside this one.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property int countdownTriggerPercent: 5
  readonly property int noticePercent: 15
  property bool noticeSent: false
  readonly property int countdownWindowSec: 60
  property bool countdownActive: false
  property bool previewMode: false
  property int secondsLeft: 60
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
    if (previewMode) return
    if (!isDischarging()) {
      noticeSent = false
      stopCountdown()
      return
    }
    if (!noticeSent && batteryLevel >= 0 && batteryLevel <= noticePercent && batteryLevel > countdownTriggerPercent) {
      noticeSent = true
      noticeProcess.running = true
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
    if (!previewMode && !isDischarging()) {
      stopCountdown()
      return
    }

    var left = Math.ceil((countdownDeadlineMs - Date.now()) / 1000)
    if (left < 0) left = 0
    secondsLeft = left
    if (left <= 0) {
      if (previewMode) stopCountdown()
      else hibernateNow()
    }
  }

  function stopCountdown() {
    countdownTimer.running = false
    countdownActive = false
    previewMode = false
    secondsLeft = countdownWindowSec
    countdownDeadlineMs = 0
  }

  // Shows the real popup and countdown, but ends by hiding instead of hibernating.
  IpcHandler {
    target: "timon.battery"
    function preview(): void {
      if (root.countdownActive && !root.previewMode) return
      root.previewMode = true
      root.startCountdown()
    }
    function cancelPreview(): void { if (root.previewMode) root.stopCountdown() }
  }

  function hibernateNow() {
    if (root.previewMode) { stopCountdown(); return }
    if (hibernateProcess.running) return
    countdownTimer.running = false
    countdownActive = false
    hibernateProcess.running = true
  }

  Process {
    id: hibernateProcess
    command: ["omarchy-battery-hibernate"]
  }

  Process {
    id: noticeProcess
    command: ["omarchy-notification-send", "Battery " + root.noticePercent + "%",
      "Time to find a charger. At " + root.countdownTriggerPercent + "% the laptop hibernates to save your work."]
  }

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
    WlrLayershell.namespace: "omarchy-battery-hibernate"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: card }

    // Omarchy style: flat card on the theme background, thin border and the
    // countdown in the theme's urgent colour, monospace UI font, theme radius.
    readonly property color urgent: Color.urgent
    readonly property color text: Color.popups.text

    Rectangle {
      id: card
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: Style.space(72)
      width: Style.space(340)
      height: content.implicitHeight + Style.space(20) * 2
      radius: Style.cornerRadius
      color: Util.alpha(Color.background, 0.97)
      border.width: Math.max(1, Style.space(2))
      border.color: panel.urgent

      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Column {
        id: content
        anchors.centerIn: parent
        width: parent.width - Style.space(20) * 2
        spacing: Style.space(10)

        Row {
          width: parent.width
          Text {
            width: parent.width / 2
            text: "Battery " + (root.batteryLevel >= 0 ? root.batteryLevel + "%" : "low")
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            color: panel.urgent
          }
          Text {
            width: parent.width / 2
            text: BatteryModel.formatCountdown(root.secondsLeft)
            horizontalAlignment: Text.AlignRight
            font.family: Style.font.family
            font.pixelSize: Style.font.displayLarge
            font.bold: true
            color: panel.urgent
          }
        }

        // Time left, shrinking towards the left.
        Rectangle {
          width: parent.width
          height: Math.max(Style.space(4), 2)
          color: Util.alpha(panel.text, 0.15)
          Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.secondsLeft / root.countdownWindowSec))
            height: parent.height
            color: panel.urgent
          }
        }

        Text {
          width: parent.width
          text: root.previewMode ? "Preview: it will not hibernate"
            : "Hibernating to save your work. Plug in to cancel."
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          color: Util.alpha(panel.text, 0.75)
          wrapMode: Text.WordWrap
        }

        Rectangle {
          id: nowButton
          width: nowLabel.implicitWidth + Style.space(12) * 2
          height: nowLabel.implicitHeight + Style.space(6) * 2
          radius: Style.cornerRadius
          color: nowMouse.containsMouse ? Util.alpha(panel.urgent, 0.15) : "transparent"
          border.width: 1
          border.color: Util.alpha(panel.urgent, 0.6)
          Text {
            id: nowLabel
            anchors.centerIn: parent
            text: "Hibernate now"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: panel.urgent
          }
          MouseArea {
            id: nowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.hibernateNow()
          }
        }
      }
    }
  }
}
