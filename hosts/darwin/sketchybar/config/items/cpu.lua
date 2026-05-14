local colors = require("colors")
local icons = require("icons")

local cpu = sbar.add("item", "cpu", {
  position = "right",
  icon = {
    string = icons.cpu,
    font = { family = "Hack Nerd Font", style = "Bold", size = 12.0 },
    color = colors.green,
    padding_left = 10,
  },
  label = {
    font = { family = "SF Pro", style = "Medium", size = 11.0 },
    color = colors.subtext0,
    padding_right = 10,
  },
  background = {
    drawing = true,
    color = colors.surface1,
    corner_radius = 8,
    height = 28,
  },
  update_freq = 3,
  padding_left = 2,
  padding_right = 2,
})

cpu:subscribe({ "forced", "routine" }, function()
  sbar.exec("ps -A -o %cpu | awk '{s+=$1} END {printf \"%.0f\", s/8}'", function(result)
    local usage = tonumber(result) or 0
    local color = colors.green
    if usage > 80 then
      color = colors.red
    elseif usage > 50 then
      color = colors.yellow
    end
    cpu:set({
      icon = { color = color },
      label = { string = usage .. "%" },
    })
  end)
end)
