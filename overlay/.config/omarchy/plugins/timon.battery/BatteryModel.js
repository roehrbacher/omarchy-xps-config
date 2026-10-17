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

// Full-charge notice, once per plugged-in session. Returns {fire, sent}.
// Unplugging re-arms it; so does dropping below rearmPercent while plugged in.
function fullChargeStep(level, pluggedIn, sent, threshold, rearmPercent) {
  if (!pluggedIn) return { fire: false, sent: false }
  if (sent && level >= 0 && level < rearmPercent) sent = false
  if (!sent && level >= 0 && level >= threshold) return { fire: true, sent: true }
  return { fire: false, sent: sent }
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
    fullChargeStep: fullChargeStep,
    formatCountdown: formatCountdown
  }
}
