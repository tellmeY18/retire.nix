local colors = require("colors")
local icons = require("icons")

-- Register AeroSpace workspace change event.
sbar.add("event", "aerospace_workspace_change")

-- Icon map: app name → sketchybar-app-font glyph.
-- This font maps common app names to icons. See:
-- https://github.com/kvndrsslr/sketchybar-app-font
local app_icons = {
  ["Arc"]              = ":arc:",
  ["Code"]             = ":code:",
  ["Discord"]          = ":discord:",
  ["Finder"]           = ":finder:",
  ["Firefox"]          = ":firefox:",
  ["Google Chrome"]    = ":google_chrome:",
  ["Kitty"]            = ":kitty:",
  ["Mail"]             = ":mail:",
  ["Messages"]         = ":messages:",
  ["Music"]            = ":music:",
  ["Notes"]            = ":notes:",
  ["Notion"]           = ":notion:",
  ["Obsidian"]         = ":obsidian:",
  ["Preview"]          = ":preview:",
  ["Safari"]           = ":safari:",
  ["Signal"]           = ":signal:",
  ["Slack"]            = ":slack:",
  ["Spotify"]          = ":spotify:",
  ["System Settings"]  = ":gear:",
  ["Telegram"]         = ":telegram:",
  ["Terminal"]         = ":terminal:",
  ["Thunderbird"]      = ":thunderbird:",
  ["VLC"]              = ":vlc:",
  ["WezTerm"]          = ":wezterm:",
  ["WhatsApp"]         = ":whats_app:",
  ["Zed"]              = ":zed:",
  ["Zen"]              = ":zen_browser:",
}

local spaces = {}

for i = 1, 10 do
  local space = sbar.add("item", "space." .. i, {
    icon = {
      string = tostring(i),
      font = { family = "Hack Nerd Font", style = "Bold", size = 13.0 },
      color = colors.overlay0,
      padding_left = 8,
      padding_right = 0,
    },
    label = {
      string = "",
      font = { family = "sketchybar-app-font", style = "Regular", size = 14.0 },
      color = colors.overlay0,
      padding_left = 4,
      padding_right = 8,
      y_offset = -1,
    },
    background = {
      drawing = true,
      color = colors.surface0,
      corner_radius = 8,
      height = 28,
    },
    padding_left = 2,
    padding_right = 2,
    click_script = "aerospace workspace " .. i,
  })

  spaces[i] = space

  -- Update workspace appearance on focus change.
  space:subscribe("aerospace_workspace_change", function(env)
    local focused = env.FOCUSED_WORKSPACE == tostring(i)

    -- Get windows in this workspace for the app icons.
    sbar.exec("/run/current-system/sw/bin/aerospace list-windows --workspace " .. i .. " --format '%{app-name}' 2>/dev/null", function(result)
      local icon_line = ""
      if result then
        for app in result:gmatch("[^\r\n]+") do
          local mapped = app_icons[app]
          if mapped then
            icon_line = icon_line .. mapped
          end
        end
      end

      local has_windows = icon_line ~= ""

      sbar.animate("tanh", 10, function()
        space:set({
          icon = {
            color = focused and colors.crust or (has_windows and colors.text or colors.overlay0),
          },
          label = {
            string = icon_line,
            color = focused and colors.crust or colors.subtext0,
          },
          background = {
            color = focused and colors.blue or (has_windows and colors.surface1 or colors.surface0),
          },
        })
      end)
    end)
  end)
end

-- Spacer between workspace groups.
sbar.add("item", "space_sep", {
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = 4,
  padding_right = 4,
})
