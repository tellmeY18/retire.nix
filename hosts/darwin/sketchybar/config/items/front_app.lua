local colors = require("colors")

local front_app = sbar.add("item", "front_app", {
  icon = {
    font = { family = "sketchybar-app-font", style = "Regular", size = 16.0 },
    color = colors.text,
    padding_left = 10,
    padding_right = 4,
  },
  label = {
    font = { family = "SF Pro", style = "Semibold", size = 13.0 },
    color = colors.subtext0,
    padding_right = 10,
  },
  background = {
    drawing = true,
    color = colors.surface1,
    corner_radius = 8,
    height = 28,
  },
  padding_left = 6,
})

-- Map of app names to sketchybar-app-font icons.
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
  ["WezTerm"]          = ":wezterm:",
  ["WhatsApp"]         = ":whats_app:",
  ["Zed"]              = ":zed:",
  ["Zen"]              = ":zen_browser:",
}

front_app:subscribe("front_app_switched", function(env)
  local app_icon = app_icons[env.INFO] or ":default:"
  sbar.animate("tanh", 10, function()
    front_app:set({
      icon = { string = app_icon },
      label = { string = env.INFO },
    })
  end)
end)
