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

// Hibernate trigger from ~/.config/omarchy/low-battery-hibernate.conf
// ("HIBERNATE_PERCENT=6"). Missing, empty or invalid: 5. Allowed: 1..50.
// Insomnia (omarchy-insomnia) reads the same file with the same rule.
function parseTriggerPercent(text) {
  var m = /^[ \t]*HIBERNATE_PERCENT[ \t]*=[ \t]*["']?([0-9]+)["']?[ \t]*(#.*)?$/m.exec(String(text || ""))
  var n = m ? parseInt(m[1], 10) : NaN
  return n >= 1 && n <= 50 ? n : 5
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
    formatCountdown: formatCountdown,
    parseTriggerPercent: parseTriggerPercent
  }
}
