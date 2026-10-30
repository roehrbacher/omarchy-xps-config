-- Managed by omarchy-xps-config. XPS-only key bindings
-- (loaded from bindings.lua after hypr/shared-bindings.lua).

-- Voxtype push-to-talk: hold Right Super (key name Super_R; a raw code:134 bind matched key-less events here and fired by itself) or the
-- Copilot key (sends Super+Shift+code:201, in the right-Super spot on this
-- keyboard) to dictate, release to paste. Replaces the stock F9 push-to-talk
-- and the stock Copilot-key Omarchy menu. Neither key alone triggers any
-- other bind; Voxtype pastes only after all modifiers are released.
hl.unbind("F9")
hl.unbind("SUPER + SHIFT + code:201")
o.bind("Super_R", "Start dictation (push-to-talk)", "voxtype record start", { repeating = false })
o.bind("Super_R", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
o.bind("SUPER + Super_R", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })
o.bind("SUPER + SHIFT + code:201", "Start dictation (push-to-talk)", "voxtype record start", { repeating = false })
o.bind("SUPER + SHIFT + code:201", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- Middle mouse button (and three-finger click on the touchpad) plays/pauses.
o.bind("mouse:274", "Play/Pause", "omarchy-shell media playPause", { locked = true })

-- Super+Shift+Space stays free (stock: toggle the top bar).
hl.unbind("SUPER + SHIFT + SPACE")

-- Lid: bound in the shared repo (omarchy-lid, generic laptop handling).
-- Closing the lid suspends, on battery and on AC (intended, stock logind
-- behaviour); an Insomnia session keeps it running closed.
