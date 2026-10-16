-- Managed by omarchy-xps-config. XPS touchpad, scrolling and gestures
-- (loaded from input.lua after hypr/shared-input.lua).

hl.config({
  input = {
    -- Pointer speed for the touchpad (default: 0, range -1.0 to 1.0).
    sensitivity = -0.08,

    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Clickfinger: 1/2/3 fingers = left/right/middle. A three-finger
      -- press is then bindable as play/pause (see machine-bindings.lua).
      clickfinger_behavior = true,

      -- Native Omarchy popups are layer-shell and cannot take a per-window
      -- scroll_touchpad rule, so they use this global factor. Chromium-based
      -- apps are pinned slower below.
      scroll_factor = 1.0,
    },
  },
})

-- Three scroll profiles. Hyprland class match is RE2 FullMatch (entire
-- class string), so prefixes need .*. Last matching rule wins.
--
--   1.0  native GTK/Qt and Omarchy layer-shell popups (the global factor)
--   1.5  terminals / TUIs — same as Grok Build (org.omarchy.agent)
--   0.08 Chromium, PWAs, Electron, CEF, Firefox — same as YouTube

-- Foot, Omarchy TUI app-ids (Grok, btop, lazygit, …), and other terminals.
o.window(
  "(Alacritty|kitty|foot|org\\.codeberg\\.dnkl\\.foot|wezterm|org\\.omarchy\\..*|TUI\\..*)",
  { scroll_touchpad = 1.5 }
)
-- Ghostty reports denser wheel events than foot; keep Omarchy's stock factor.
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Web engines. brave-.* / chrome-.* cover the browser and every PWA
-- (brave-youtube.com__-Default, Chrome Bitwarden window, …).
o.window({ tag = "chromium-based-browser" }, { scroll_touchpad = 0.08 })
o.window({ tag = "firefox-based-browser" }, { scroll_touchpad = 0.08 })
o.window(
  "(brave-.*|google-chrome.*|chrome-.*|[Cc]hromium.*|microsoft-edge.*|vivaldi.*|opera.*|helium.*|[fF]irefox.*|[zZ]en(-browser)?|librewolf.*|[Bb]itwarden|1[Pp]assword|md\\.obsidian\\.Obsidian|[Hh]ermes|[Dd]iscord|[Ss]lack|[Ss]potify|^[Cc]ode$|code-oss|[Cc]ursor|grok-bot|[Ss]ignal|minecraft-launcher.*)",
  { scroll_touchpad = 0.08 }
)

-- Ente Photos reports class "ente" and uses dense wheel events like
-- Chromium. Keep this last so it wins over any broader match.
o.window("^ente$", { scroll_touchpad = 0.08, scroll_mouse = 0.08 })

-- Files (GTK) is too fast at the global 1.0; keep Omawrite at 1.0.
o.window("org\\.gnome\\.Nautilus", { scroll_touchpad = 0.3, scroll_mouse = 0.3 })

-- Wayland app-id is org.telegram.desktop. TelegramDesktop is the X11
-- class only, so a rule for that name never applied.
o.window("(TelegramDesktop|org\\.telegram\\.desktop)", { scroll_touchpad = 0.3, scroll_mouse = 0.3 })

-- Steam is XWayland. 0.08 was painfully slow, 1.0 is too fast.
o.window("[Ss]team.*", { scroll_touchpad = 0.3, scroll_mouse = 0.3 })

-- LocalSend is Flutter and feels like Chromium-density scrolling.
o.window("(localsend|org\\.localsend\\.localsend_app)", { scroll_touchpad = 0.08, scroll_mouse = 0.08 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 3-finger down/up: show-desktop, restore, Super+Space menu, or dismiss it.
require("hypr.show-desktop")
