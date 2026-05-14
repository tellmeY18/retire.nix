local colors = require("colors")
local icons = require("icons")

local cal = sbar.add("item", "calendar", {
  position = "right",
  icon = {
    string = icons.clock,
    font = { family = "Hack Nerd Font", style = "Bold", size = 12.0 },
    color = colors.mauve,
    padding_left = 10,
  },
  label = {
    font = { family = "SF Pro", style = "Semibold", size = 13.0 },
    color = colors.text,
    padding_right = 10,
  },
  background = {
    drawing = true,
    color = colors.surface1,
    corner_radius = 8,
    height = 28,
  },
  update_freq = 30,
  padding_right = 2,
})

cal:subscribe({ "forced", "routine" }, function()
  cal:set({ label = os.date("%a %d %b  %H:%M") })
end)
