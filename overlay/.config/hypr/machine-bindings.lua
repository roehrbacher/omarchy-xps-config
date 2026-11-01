-- Managed by omarchy-xps-config. XPS-only key bindings
-- (loaded from bindings.lua after hypr/shared-bindings.lua).

-- Voxtype: hold Super+D to talk, release to paste (push-to-talk).
-- Replaces the stock F9 push-to-talk. The stock Copilot-key Omarchy menu
-- stays unbound, so the Copilot key does nothing on its own.
hl.unbind("F9")
hl.unbind("SUPER + SHIFT + code:201")
o.bind("SUPER + D", "Start dictation (push-to-talk)", "voxtype record start", { repeating = false })
o.bind("SUPER + D", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
-- If Super is let go before D, the D release no longer matches SUPER + D, so
-- also stop on the Super release. Hyprland may report that release with or
-- without SUPER still set, so bind both (a stop while idle does nothing).
o.bind("SUPER + Super_L", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true, non_consuming = true })
o.bind("Super_L", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true, non_consuming = true })

-- Workspace keys by key name instead of stock code:10..19. This laptop's
-- hotkey/sensor devices send key-less events; Hyprland matches those against
-- every code:N bind with the held modifiers. While the Copilot key (Super+Shift)
-- was held for dictation, one such burst ran "move window to workspace 1..10"
-- in order and left the window on workspace 10 (2026-11-01 10:06:18).
-- Digits are unshifted on the German layout, so names behave the same.
local digits = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
for workspace = 1, 10 do
  local code = "code:" .. tostring(workspace + 9)
  local key = digits[workspace]
  hl.unbind("SUPER + " .. code)
  hl.unbind("SUPER + SHIFT + " .. code)
  hl.unbind("SUPER + SHIFT + ALT + " .. code)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace), follow = false }))
end
for index = 1, 5 do
  hl.unbind("SUPER + ALT + code:" .. tostring(index + 9))
  o.bind("SUPER + ALT + " .. digits[index], "Switch to group window " .. index, hl.dsp.group.active({ index = index }))
end

-- Middle mouse button (and three-finger click on the touchpad) plays/pauses.
o.bind("mouse:274", "Play/Pause", "omarchy-shell media playPause", { locked = true })

-- Super+Shift+Space stays free (stock: toggle the top bar).
hl.unbind("SUPER + SHIFT + SPACE")

-- Lid: bound in the shared repo (omarchy-lid, generic laptop handling).
-- Closing the lid suspends, on battery and on AC (intended, stock logind
-- behaviour); an Insomnia session keeps it running closed.
