local colors = require("colors")
local icons = require("icons")

local apple = sbar.add("item", "apple", {
  icon = {
    string = icons.apple,
    font = { family = "Hack Nerd Font", style = "Bold", size = 16.0 },
    color = colors.blue,
    padding_left = 10,
    padding_right = 10,
  },
  label = { drawing = false },
  background = {
    drawing = true,
    color = colors.surface1,
    corner_radius = 8,
    height = 28,
  },
  click_script = "open -a 'System Settings'",
  padding_left = 2,
  padding_right = 6,
})
