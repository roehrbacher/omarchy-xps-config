-- Managed by omarchy-xps-config. Loaded from hypr/machine-input.lua.
-- Four-finger touchpad swipes (three-finger swipes stay workspace /
-- show-desktop, see machine-input.lua and show-desktop.lua):
--   up / down    volume up / down live, 1 % per STEP px of finger travel,
--                with the stock volume OSD (throttled)
--   left         (right to left) next track
--   right        (left to right) previous track
-- Same commands as the stock media keys (default/hypr/bindings/media.lua).
-- Undo: remove the require line in machine-input.lua.

local STEP = 9     -- px of finger travel per 1 % volume (live, while moving)
local TRACK = 80   -- px of horizontal travel needed to skip a track

-- gesture-volume (in ~/.local/bin) resolves the sink once per swipe and
-- applies each update as one fast relative step, so the volume follows the
-- fingers instead of lagging behind a queue of slow full volume commands.
local function volume(direction, sign)
  local acc = 0
  hl.gesture({
    fingers = 4,
    direction = direction,
    action = {
      start = function()
        acc = 0
        hl.exec_cmd("gesture-volume begin")
      end,
      update = function(event)
        if not event or not event.delta then return end
        acc = acc + math.abs(event.delta.y or 0)
        local steps = math.floor(acc / STEP)
        if steps > 0 then
          acc = acc - steps * STEP
          hl.exec_cmd("gesture-volume " .. sign .. steps)
        end
      end,
      finish = function()
        acc = 0
        hl.exec_cmd("gesture-volume end")
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

volume("up", "+")
volume("down", "-")
track("left", "omarchy-shell media next")
track("right", "omarchy-shell media previous")
