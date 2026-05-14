local colors = require("colors")
local icons = require("icons")

local memory = sbar.add("item", "memory", {
  position = "right",
  icon = {
    string = icons.memory,
    font = { family = "Hack Nerd Font", style = "Bold", size = 14.0 },
    color = colors.peach,
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
  update_freq = 5,
  padding_left = 2,
  padding_right = 2,
})

memory:subscribe({ "forced", "routine" }, function()
  sbar.exec("memory_pressure 2>/dev/null | grep 'System-wide memory free percentage' | awk '{print 100-$NF}'", function(result)
    local usage = tonumber(result:match("%d+")) or 0
    local color = colors.peach
    if usage > 80 then
      color = colors.red
    elseif usage > 60 then
      color = colors.yellow
    end
    memory:set({
      icon = { color = color },
      label = { string = usage .. "%" },
    })
  end)
end)
