-- Managed by omarchy-xps-config. Loaded from hypr/machine-input.lua.
-- Four-finger touchpad swipes (three-finger swipes stay workspace /
-- show-desktop, see machine-input.lua and show-desktop.lua):
--   up / down    volume up / down, one step per STEP px while the fingers
--                keep moving (continuous), with the stock volume OSD
--   left         (right to left) next track
--   right        (left to right) previous track
-- Same commands as the stock media keys (default/hypr/bindings/media.lua).
-- Undo: remove the require line in machine-input.lua.

local STEP = 45    -- px of finger travel per volume step
local TRACK = 80   -- px of horizontal travel needed to skip a track

local function volume(direction, cmd)
  local acc = 0
  hl.gesture({
    fingers = 4,
    direction = direction,
    action = {
      start = function()
        acc = 0
        hl.exec_cmd(cmd)
      end,
      update = function(event)
        if not event or not event.delta then return end
        acc = acc + math.abs(event.delta.y or 0)
        while acc >= STEP do
          acc = acc - STEP
          hl.exec_cmd(cmd)
        end
      end,
      finish = function() acc = 0 end,
    },
  })
end

local function track(direction, cmd)
  local acc = 0
  hl.gesture({
    fingers = 4,
    direction = direction,
    action = {
      start = function() acc = 0 end,
      update = function(event)
        if event and event.delta then acc = acc + math.abs(event.delta.x or 0) end
      end,
      finish = function(event)
        if event and event.cancelled == true then return end
        if acc >= TRACK then hl.exec_cmd(cmd) end
        acc = 0
      end,
    },
  })
end

volume("up", "omarchy-audio-output-volume raise")
volume("down", "omarchy-audio-output-volume lower")
track("left", "omarchy-shell media next")
track("right", "omarchy-shell media previous")
