-- Managed by omarchy-xps-config. XPS window rules (loaded from hyprland.lua).

-- Bitwarden and the Omarchy update terminal are tagged floating by Omarchy.
-- These load later, so tile wins. The update launcher always uses
-- org.omarchy.terminal titled "Omarchy", so other Update-menu terminals tile too.
o.window("^(Bitwarden)$", { tag = "-floating-window", float = false, tile = true })
o.window("chrome-nngceckbapebfimnlniiiahkandclblb-Default", {
  tag = "-floating-window",
  float = false,
  tile = true,
})
o.window({
  class = "^org\\.omarchy\\.terminal$",
  title = "^Omarchy$",
}, { tag = "-floating-window", float = false, tile = true })

-- Moonlight streaming window (from the gaming PC's Sunshine).
require("hypr.moonlight")
