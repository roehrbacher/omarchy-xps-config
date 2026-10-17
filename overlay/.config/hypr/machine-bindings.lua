-- Managed by omarchy-xps-config. XPS-only key bindings
-- (loaded from bindings.lua after hypr/shared-bindings.lua).

-- Voxtype: hold the Copilot key (sends Super+Shift+code:201) to dictate,
-- release to type. Replaces the stock F9 push-to-talk and the stock
-- Copilot-key Omarchy menu.
hl.unbind("F9")
hl.unbind("SUPER + SHIFT + code:201")
o.bind("SUPER + SHIFT + code:201", "Start dictation (push-to-talk)", "voxtype record start")
o.bind("SUPER + SHIFT + code:201", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- Middle mouse button (and three-finger click on the touchpad) plays/pauses.
o.bind("mouse:274", "Play/Pause", "omarchy-shell media playPause", { locked = true })

-- Super+Shift+Space stays free (stock: toggle the top bar).
hl.unbind("SUPER + SHIFT + SPACE")

-- Lid: bound in the shared repo (omarchy-lid, generic laptop handling).
-- Closing the lid suspends, on battery and on AC (intended, stock logind
-- behaviour); an Insomnia session keeps it running closed.
