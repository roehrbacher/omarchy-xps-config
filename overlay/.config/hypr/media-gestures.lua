-- Managed by omarchy-xps-config. Loaded from hypr/machine-input.lua.
-- Four-finger touchpad swipes (three-finger swipes stay workspace /
-- show-desktop, see machine-input.lua and show-desktop.lua):
--   up / down    volume follows the fingers live (1 % per STEP px), both
--                ways within one swipe, with the shell volume OSD
--   left         (right to left) next track
--   right        (left to right) previous track
-- Same commands as the stock media keys (default/hypr/bindings/media.lua).
-- Undo: remove the require line in machine-input.lua.

local STEP = 9      -- px of finger travel per 1 % volume
local TRACK = 80    -- px of horizontal travel needed to skip a track

-- Hyprland locks a gesture's direction at its start (separate up / down
-- binds), but event.delta is the signed raw vertical movement in px (down is
-- positive) on every update (~7 ms apart). So both binds do the same thing:
-- volume follows the signed finger movement 1:1, both ways within one swipe.
-- gesture-volume (~/.local/bin) hands each delta to the running shell, which
-- sets the volume in-process like the popup slider.
local function dy(event)
  local d = event and event.delta
  if type(d) == "number" then return d end
  if type(d) == "table" or type(d) == "userdata" then return d.y or 0 end
  return 0
end

local function volume(direction)
  hl.gesture({
    fingers = 4,
    direction = direction,
    action = {
      start = function() end,
      finish = function() end,
      update = function(event)
        local pct = -dy(event) / STEP   -- fingers up = louder
        if pct ~= 0 then hl.exec_cmd(string.format("gesture-volume %+.3f", pct)) end
      end,
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

volume("up")
volume("down")
track("left", "omarchy-shell media next")
track("right", "omarchy-shell media previous")
