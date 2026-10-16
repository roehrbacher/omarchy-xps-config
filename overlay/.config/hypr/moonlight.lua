-- Managed by omarchy-xps-config. Loaded from hypr/machine-windows.lua.
-- Moonlight on the XPS (eDP-1 1920x1200, Hyprland scale 1.5 -> 1280x800 logical).
--
-- The PC streams 1920x1080 (Moonlight.conf: width=1920 height=1080,
-- bitrate=40000, H.264). For a sharp picture the stream window must be exactly
-- 1920x1080 *physical* pixels, so stream pixels map 1:1 to screen pixels:
--   logical size = 1920/scale x 1080/scale = 1280 x 720 at scale 1.5
-- That fills the full width; the 16:10 panel leaves 80 logical px below.
-- If the display scale changes, set STREAM_W/H to 1920/scale and 1080/scale.
-- No compositor fullscreen (it wobbles), no pin; the launcher window keeps
-- maximize suppressed.

local SCALE = 1.5
local STREAM_W = math.floor(1920 / SCALE + 0.5)
local STREAM_H = math.floor(1080 / SCALE + 0.5)

local ML = "com.moonlight_stream.Moonlight"

o.window(ML, {
  float = true,
  fullscreen = false,
  animation = "none",
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "focus",
})

o.window({ class = ML, title = "^Moonlight$" }, {
  float = true,
  fullscreen = false,
  animation = "none",
  suppress_event = "maximize",
})

o.window({ class = ML, title = ".+ - Moonlight$" }, {
  float = true,
  fullscreen = false,
  animation = "none",
  idle_inhibit = "focus",
  tag = "-default-opacity",
  opacity = "1 1",
  size = { STREAM_W, STREAM_H },
  move = { 0, 0 },
  border_size = 0,
})
