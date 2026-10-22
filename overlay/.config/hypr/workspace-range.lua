-- Managed by omarchy-xps-config. Lets the smooth stock 3-finger swipe reach
-- every workspace from lowest occupied - 1 (min 1) to highest occupied + 1
-- (max 10), empty ones in between included (same range as Super+wheel).
--
-- The stock swipe (m-1/m+1) only visits workspaces that exist, and
-- workspace_swipe_create_new (stock: on) already adds highest + 1. So this
-- keeps the empty ones in lowest - 1 .. highest alive with persistent
-- workspace rules, re-checked on window open/close/move.
--
-- Rule strings are "0N" (resolve to workspace N) so they never merge with
-- show-desktop's own "N" rules. Undo: delete the require line in
-- machine-input.lua (and this file).

local rules = {}

local function rule(id)
  if not rules[id] then
    rules[id] = hl.workspace_rule({ workspace = "0" .. tostring(id), persistent = true })
  end
  return rules[id]
end

local function sync()
  local count, lo, hi = {}, nil, nil
  for _, ws in ipairs(hl.get_workspaces() or {}) do
    local id = ws.id
    if id and id >= 1 and id <= 10 and not ws.special then
      count[id] = ws.windows or 0
      if count[id] > 0 then
        lo = (lo == nil or id < lo) and id or lo
        hi = (hi == nil or id > hi) and id or hi
      end
    end
  end
  for id = 1, 10 do
    local keep = lo ~= nil and id >= math.max(1, lo - 1) and id <= hi and (count[id] or 0) == 0
    if keep then
      rule(id):set_enabled(true)
    elseif rules[id] then
      rules[id]:set_enabled(false)
    end
  end
end

-- Debounced: window.destroy fires before the window leaves its workspace.
local pending = false
local function schedule()
  if pending then return end
  pending = true
  hl.timer(function()
    pending = false
    sync()
  end, { timeout = 80, type = "oneshot" })
end

for _, ev in ipairs({ "window.open", "window.destroy", "window.close", "window.move_to_workspace", "workspace.removed" }) do
  hl.on(ev, schedule)
end
schedule()
