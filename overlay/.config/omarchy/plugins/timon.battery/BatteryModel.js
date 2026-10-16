function batteryPercentage(device) {
  if (!device || !device.isPresent) return -1
  return Math.round(Number(device.percentage || 0) * 100)
}

function isDischarging(device, onBattery, dischargingState) {
  return !!(device && device.isPresent && onBattery && device.state === dischargingState)
}

function shouldStartCountdown(level, active, triggerPercent) {
  if (active) return true
  var trigger = triggerPercent == null ? 5 : triggerPercent
  return level >= 0 && level <= trigger
}

function formatCountdown(sec) {
  var n = Math.max(0, Math.round(Number(sec) || 0))
  var m = Math.floor(n / 60)
  var s = n % 60
  return m + ":" + (s < 10 ? "0" : "") + s
}

if (typeof module !== "undefined") {
  module.exports = {
    batteryPercentage: batteryPercentage,
    isDischarging: isDischarging,
    shouldStartCountdown: shouldStartCountdown,
    formatCountdown: formatCountdown
  }
}
