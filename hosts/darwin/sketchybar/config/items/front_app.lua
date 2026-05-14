local colors = require("colors")
local icons = require("icons")

local front_app = sbar.add("item", "front_app", {
  icon = {
    string = icons.front_app,
    font = { family = "Hack Nerd Font", style = "Bold", size = 14.0 },
    color = colors.teal,
    padding_left = 10,
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

front_app:subscribe("front_app_switched", function(env)
  local app_icon = icons.apps[env.INFO] or icons.apps.Default
  front_app:set({
    icon = { string = app_icon },
    label = { string = env.INFO },
  })
end)
