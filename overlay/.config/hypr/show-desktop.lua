-- Managed by omarchy-xps-config. Loaded from hypr/machine-input.lua.
-- Three-finger vertical swipe:
--   down  — hide windows (show desktop), or close the Omarchy menu if it is open
--   up    — restore hidden windows, or open the workspace overview
--           (timon.overview) if none; down closes the overview when it is open
-- Horizontal workspace swipe stays in input.lua.
--
-- Windows stay on the current workspace, floated and slid off the bottom so
-- swipe-up can track fingers without a special-workspace hop.

local HOLD_PREFIX = "showdesk-"
local PARK_TAG = "showdesk"
local COMMIT_RATIO = 0.2
local FLICK_RATIO = 0.08
local FLICK_PX_PER_MS = 0.7

local persist_rules = {}
local memory = {}
local session = nil
local layout_snapshot = nil

local function window_sel(address)
  return "address:" .. address
end

local function vec_xy(value)
  if type(value) ~= "table" then
    return 0, 0
  end
  return value.x or value[1] or 0, value.y or value[2] or 0
end

local function travel_px()
  local monitor = hl.get_active_monitor()
  if monitor and monitor.height and monitor.height > 0 then
    return monitor.height
  end
  if monitor then
    local _, h = vec_xy(monitor.size)
    if h > 0 then
      return h
    end
  end
  return 900
end

local function set_prop(address, prop, value)
  hl.dispatch(hl.dsp.window.set_prop({
    prop = prop,
    value = value,
    window = window_sel(address),
  }))
end

local function set_tag(address, spec)
  hl.dispatch(hl.dsp.window.tag({
    tag = spec,
    window = window_sel(address),
  }))
end

local function window_has_park_tag(window)
  local tags = window and window.tags
  if type(tags) == "string" then
    return tags:find(PARK_TAG, 1, true) ~= nil
  end
  if type(tags) == "table" then
    for _, tag in pairs(tags) do
      if tostring(tag):find(PARK_TAG, 1, true) then
        return true
      end
    end
  end
  return false
end

local function capture_layout_opts()
  if layout_snapshot then
    return
  end
  layout_snapshot = {
    aspect = hl.get_config("layout.single_window_aspect_ratio"),
    preserve = hl.get_config("dwindle.preserve_split"),
  }
end

local function restore_layout_opts()
  local snap = layout_snapshot
  layout_snapshot = nil
  if not snap then
    return
  end
  hl.config({
    dwindle = { preserve_split = snap.preserve },
    layout = { single_window_aspect_ratio = snap.aspect },
  })
end

local function keep_workspace(workspace_id)
  local key = tostring(workspace_id)
  local rule = persist_rules[key]
  if rule then
    rule:set_enabled(true)
    return
  end
  persist_rules[key] = hl.workspace_rule({
    workspace = key,
    persistent = true,
  })
end

local function drop_workspace(workspace_id)
  local rule = persist_rules[tostring(workspace_id)]
  if rule then
    rule:set_enabled(false)
  end
end

local function stash_empty(stash)
  if not stash or not stash.by_address then
    return true
  end
  return next(stash.by_address) == nil
end

local function drop_stash(workspace_id)
  memory[workspace_id] = nil
  drop_workspace(workspace_id)
end

local function is_parked(address, workspace_id)
  local stash = memory[workspace_id]
  return stash and stash.by_address and stash.by_address[address] ~= nil
end

local function skip_window(window)
  if not window or not window.mapped then
    return true
  end
  if window.hidden or window.pinned then
    return true
  end
  local workspace = window.workspace
  if not workspace or workspace.special then
    return true
  end
  if is_parked(window.address, workspace.id) or window_has_park_tag(window) then
    return true
  end
  return false
end

local function snapshot(window)
  local x, y = vec_xy(window.at)
  local w, h = vec_xy(window.size)
  return {
    address = window.address,
    floating = window.floating == true,
    x = x,
    y = y,
    w = w,
    h = h,
    fullscreen = window.fullscreen or 0,
  }
end

local function extra_for(stash, address)
  return stash and stash.by_address and stash.by_address[address] or nil
end

hl.on("window.destroy", function(window)
  if not window or not window.address then
    return
  end
  local gone = {}
  for workspace_id, stash in pairs(memory) do
    if stash.focused == window.address then
      stash.focused = nil
    end
    if stash.by_address then
      stash.by_address[window.address] = nil
    end
    if stash_empty(stash) then
      table.insert(gone, workspace_id)
    end
  end
  for _, workspace_id in ipairs(gone) do
    drop_stash(workspace_id)
  end
end)

local function apply_fullscreen(selector, fullscreen)
  if fullscreen == 1 then
    hl.dispatch(hl.dsp.window.fullscreen({
      mode = "maximized",
      action = "set",
      window = selector,
    }))
  elseif fullscreen == 2 then
    hl.dispatch(hl.dsp.window.fullscreen({
      mode = "fullscreen",
      action = "set",
      window = selector,
    }))
  end
end

local function split_dir(prev, cur)
  local dx = (cur.x + cur.w / 2) - (prev.x + prev.w / 2)
  local dy = (cur.y + cur.h / 2) - (prev.y + prev.h / 2)
  if math.abs(dx) >= math.abs(dy) then
    return dx >= 0 and "r" or "l"
  end
  return dy >= 0 and "d" or "u"
end

local function pin_snapshot_box(item, y_offset)
  local selector = window_sel(item.address)
  if not hl.get_window(selector) then
    return
  end
  if not item.w or not item.h or item.w <= 0 or item.h <= 0 then
    return
  end
  hl.dispatch(hl.dsp.window.resize({
    x = item.w,
    y = item.h,
    relative = false,
    window = selector,
  }))
  hl.dispatch(hl.dsp.window.move({
    x = item.x,
    y = item.y + (y_offset or 0),
    relative = false,
    window = selector,
  }))
end

local function float_group(items)
  for _, item in ipairs(items) do
    local selector = window_sel(item.address)
    if hl.get_window(selector) then
      hl.dispatch(hl.dsp.window.float({ action = "set", window = selector }))
    end
  end
  for _, item in ipairs(items) do
    pin_snapshot_box(item)
  end
end

local function correct_swaps(tiled, stash)
  if #tiled < 2 or not stash or not stash.by_address then
    return
  end
  for i = 1, #tiled - 1 do
    local a = hl.get_window(window_sel(tiled[i]))
    local b = hl.get_window(window_sel(tiled[i + 1]))
    local sa = stash.by_address[tiled[i]]
    local sb = stash.by_address[tiled[i + 1]]
    if a and b and sa and sb then
      local ax = vec_xy(a.at)
      local bx = vec_xy(b.at)
      if (sa.x - sb.x) * (ax - bx) < 0 then
        hl.dispatch(hl.dsp.focus({ window = window_sel(tiled[i]) }))
        hl.dispatch(hl.dsp.layout("swapsplit"))
      end
    end
  end
end

local function sorted_stash_entries(stash)
  local addresses = {}
  if not stash or not stash.by_address then
    return addresses
  end
  for address, extra in pairs(stash.by_address) do
    table.insert(addresses, { address = address, extra = extra })
  end
  table.sort(addresses, function(a, b)
    if a.extra.x == b.extra.x then
      return a.extra.y < b.extra.y
    end
    return a.extra.x < b.extra.x
  end)
  return addresses
end

local function finish_restore(workspace_id, tiled, focused, fullscreen_by_address, stash)
  capture_layout_opts()
  hl.config({
    dwindle = { preserve_split = false },
    layout = { single_window_aspect_ratio = { 0, 0 } },
  })
  hl.exec_scheduled_prop_refresh_immediately()

  for index, address in ipairs(tiled) do
    local selector = window_sel(address)
    if hl.get_window(selector) then
      if index > 1 then
        local prev = extra_for(stash, tiled[index - 1])
        local cur = extra_for(stash, address)
        if prev and cur then
          hl.dispatch(hl.dsp.focus({ window = window_sel(tiled[index - 1]) }))
          hl.dispatch(hl.dsp.layout("preselect " .. split_dir(prev, cur)))
        end
      end
      hl.dispatch(hl.dsp.window.float({ action = "unset", window = selector }))
    end
  end

  for _, address in ipairs(tiled) do
    local window = hl.get_window(window_sel(address))
    if window and window.floating then
      hl.dispatch(hl.dsp.window.float({ action = "unset", window = window_sel(address) }))
    end
  end

  hl.exec_scheduled_prop_refresh_immediately()
  correct_swaps(tiled, stash)

  if #tiled == 2 then
    local left = extra_for(stash, tiled[1])
    local right = extra_for(stash, tiled[2])
    if left and right and math.abs(left.x - right.x) >= math.abs(left.y - right.y) then
      hl.dispatch(hl.dsp.focus({ window = window_sel(tiled[1]) }))
      hl.dispatch(hl.dsp.layout("splitratio 1.0 exact"))
    end
  end

  for _, address in ipairs(tiled) do
    set_tag(address, "-" .. PARK_TAG)
    set_prop(address, "no_anim", "0")
    set_prop(address, "render_unfocused", "0")
    apply_fullscreen(window_sel(address), fullscreen_by_address[address] or 0)
  end
  if focused and hl.get_window(window_sel(focused)) then
    hl.dispatch(hl.dsp.focus({ window = window_sel(focused) }))
  end
  drop_stash(workspace_id)

  hl.timer(restore_layout_opts, { timeout = 80, type = "oneshot" })
end

local function restore_tiled(workspace_id, stash)
  local tiled = {}
  local fullscreen_by_address = {}
  for _, item in ipairs(sorted_stash_entries(stash)) do
    pin_snapshot_box(item.extra)
    if item.extra.floating == true then
      set_tag(item.address, "-" .. PARK_TAG)
      set_prop(item.address, "no_anim", "0")
      set_prop(item.address, "render_unfocused", "0")
      apply_fullscreen(window_sel(item.address), item.extra.fullscreen or 0)
    else
      table.insert(tiled, item.address)
      fullscreen_by_address[item.address] = item.extra.fullscreen or 0
    end
  end

  local focused = stash and stash.focused or nil
  if #tiled == 0 then
    if focused and hl.get_window(window_sel(focused)) then
      hl.dispatch(hl.dsp.focus({ window = window_sel(focused) }))
    end
    drop_stash(workspace_id)
    restore_layout_opts()
    return
  end

  finish_restore(workspace_id, tiled, focused, fullscreen_by_address, stash)
end

local function place_session()
  if not session or not session.items then
    return
  end
  for _, item in ipairs(session.items) do
    pin_snapshot_box(item, session.offset)
  end
end

local function pulled_ratio()
  if not session or not session.travel or session.travel <= 0 then
    return 0
  end
  if session.kind == "hide" or session.kind == "dismiss_menu" or session.kind == "dismiss_overview" then
    return session.offset / session.travel
  end
  return (session.travel - session.offset) / session.travel
end

local function should_commit()
  if not session then
    return false
  end
  local ratio = pulled_ratio()
  if ratio >= COMMIT_RATIO then
    return true
  end
  return ratio >= FLICK_RATIO and math.abs(session.speed or 0) >= FLICK_PX_PER_MS
end

local function new_pointer_session(kind, fields)
  local travel = travel_px()
  session = {
    kind = kind,
    items = fields.items or {},
    stash = fields.stash,
    workspace_id = fields.workspace_id,
    offset = fields.offset or 0,
    travel = travel,
    speed = 0,
    last_time = nil,
  }
end

local function park_session()
  session.offset = session.travel
  place_session()
  for _, item in ipairs(session.items) do
    set_tag(item.address, "+" .. PARK_TAG)
    set_prop(item.address, "render_unfocused", "1")
    set_prop(item.address, "no_anim", "1")
  end
  memory[session.workspace_id] = session.stash
  keep_workspace(session.workspace_id)
end

local function visible_windows(workspace)
  local list = {}
  for _, window in ipairs(hl.get_workspace_windows(workspace) or {}) do
    if not skip_window(window) then
      table.insert(list, window)
    end
  end
  return list
end

local function omarchy_menu_visible()
  for _, layer in ipairs(hl.get_layers({ namespace = "omarchy-menu" }) or {}) do
    if layer.mapped then
      return true
    end
  end
  return false
end

local function collect_parked(workspace_id)
  local stash = memory[workspace_id] or { by_address = {}, focused = nil }
  stash.by_address = stash.by_address or {}
  local items = {}

  for _, extra in pairs(stash.by_address) do
    if hl.get_window(window_sel(extra.address)) then
      table.insert(items, extra)
    else
      stash.by_address[extra.address] = nil
    end
  end

  if #items > 0 then
    return items, stash
  end

  -- Recover after a config reload: tagged windows on this workspace.
  local workspace = hl.get_workspace(workspace_id)
  for _, window in ipairs(hl.get_workspace_windows(workspace or workspace_id) or {}) do
    if window_has_park_tag(window) then
      local extra = snapshot(window)
      extra.floating = false
      extra.y = extra.y - travel_px()
      stash.by_address[window.address] = extra
      table.insert(items, extra)
    end
  end

  -- One-time pull from the old special-workspace parking lot.
  if #items == 0 then
    for _, window in ipairs(hl.get_workspace_windows("special:" .. HOLD_PREFIX .. tostring(workspace_id)) or {}) do
      local extra = snapshot(window)
      extra.floating = false
      stash.by_address[window.address] = extra
      set_prop(window.address, "no_anim", "1")
      hl.dispatch(hl.dsp.window.move({
        workspace = workspace_id,
        follow = false,
        window = window_sel(window.address),
      }))
      table.insert(items, extra)
    end
    if #items > 0 then
      float_group(items)
    end
  end

  return items, stash
end

local function overview_visible()
  for _, layer in ipairs(hl.get_layers({ namespace = "timon-overview" }) or {}) do
    if layer.mapped then
      return true
    end
  end
  return false
end

local function begin_dismiss_menu()
  new_pointer_session("dismiss_menu", { offset = 0 })
end

local function begin_launcher()
  new_pointer_session("launcher", { offset = travel_px() })
end

local function begin_overview()
  new_pointer_session("overview", { offset = travel_px() })
end

local function begin_dismiss_overview()
  new_pointer_session("dismiss_overview", { offset = 0 })
end

local function begin_hide()
  if session then
    return
  end
  if omarchy_menu_visible() then
    begin_dismiss_menu()
    return
  end
  if overview_visible() then
    begin_dismiss_overview()
    return
  end
  local workspace = hl.get_active_workspace()
  if not workspace or workspace.special then
    return
  end
  local to_hide = visible_windows(workspace)
  if #to_hide == 0 then
    return
  end

  local workspace_id = workspace.id
  local stash = { by_address = {}, focused = nil }
  local active = hl.get_active_window()
  if active and active.workspace and active.workspace.id == workspace_id then
    stash.focused = active.address
  end

  local items = {}
  for _, window in ipairs(to_hide) do
    local snap = snapshot(window)
    stash.by_address[window.address] = snap
    set_prop(window.address, "no_anim", "1")
    if (window.fullscreen or 0) ~= 0 then
      hl.dispatch(hl.dsp.window.fullscreen({
        action = "unset",
        window = window_sel(window.address),
      }))
    end
    table.insert(items, snap)
  end

  float_group(items)
  new_pointer_session("hide", {
    items = items,
    stash = stash,
    workspace_id = workspace_id,
    offset = 0,
  })
end

local function begin_show()
  if session then
    return
  end
  local workspace = hl.get_active_workspace()
  if not workspace or workspace.special then
    return
  end
  local workspace_id = workspace.id
  local items, stash = collect_parked(workspace_id)
  if #items == 0 then
    if omarchy_menu_visible() or overview_visible() then
      return
    end
    begin_overview()
    return
  end

  for _, item in ipairs(items) do
    set_prop(item.address, "no_anim", "1")
  end

  new_pointer_session("show", {
    items = items,
    stash = stash,
    workspace_id = workspace_id,
    offset = travel_px(),
  })
  place_session()
end

local function track(event)
  if not session or not event or not event.delta then
    return
  end
  local dy = event.delta.y or 0
  if event.time_ms and session.last_time and event.time_ms > session.last_time then
    session.speed = dy / (event.time_ms - session.last_time)
  end
  session.last_time = event.time_ms
  session.offset = math.max(0, math.min(session.travel, session.offset + dy))
  place_session()
end

local function finish_gesture(event)
  if not session then
    return
  end
  local commit = event and event.cancelled ~= true and should_commit()
  local kind = session.kind

  if kind == "launcher" then
    if commit then
      hl.exec_cmd("omarchy-menu summon")
    end
  elseif kind == "overview" then
    if commit then
      hl.exec_cmd("omarchy-shell shell summon timon.overview")
    end
  elseif kind == "dismiss_overview" then
    if commit then
      hl.exec_cmd("omarchy-shell shell hide timon.overview")
    end
  elseif kind == "dismiss_menu" then
    if commit then
      hl.exec_cmd("omarchy-menu close")
    end
  elseif kind == "hide" then
    if commit then
      park_session()
    else
      session.offset = 0
      place_session()
      restore_tiled(session.workspace_id, session.stash)
    end
  elseif kind == "show" then
    if commit then
      session.offset = 0
      place_session()
      restore_tiled(session.workspace_id, session.stash)
    else
      session.offset = session.travel
      place_session()
    end
  end
  session = nil
end

hl.gesture({
  fingers = 3,
  direction = "down",
  action = {
    start = function(event)
      begin_hide()
      track(event)
    end,
    update = track,
    finish = finish_gesture,
  },
})

hl.gesture({
  fingers = 3,
  direction = "up",
  action = {
    start = function(event)
      begin_show()
      track(event)
    end,
    update = track,
    finish = finish_gesture,
  },
})
