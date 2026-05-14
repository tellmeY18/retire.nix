local colors = require("colors")
local icons = require("icons")

local battery = sbar.add("item", "battery", {
  position = "right",
  icon = {
    font = { family = "Hack Nerd Font", style = "Bold", size = 16.0 },
    padding_left = 10,
  },
  label = {
    font = { family = "SF Pro", style = "Medium", size = 11.0 },
    padding_right = 10,
  },
  background = {
    drawing = true,
    color = colors.surface1,
    corner_radius = 8,
    height = 28,
  },
  update_freq = 60,
  padding_left = 2,
  padding_right = 2,
})

local function update()
  sbar.exec("pmset -g batt", function(batt_info)
    local icon = icons.battery.full
    local color = colors.green
    local found, _, charge = batt_info:find("(%d+)%%")

    if found then
      charge = tonumber(charge)
    else
      charge = 0
    end

    local is_charging = batt_info:find("AC Power") ~= nil

    if is_charging then
      icon = icons.battery.charging
      color = colors.green
    elseif charge > 80 then
      icon = icons.battery.full
      color = colors.green
    elseif charge > 60 then
      icon = icons.battery.high
      color = colors.text
    elseif charge > 40 then
      icon = icons.battery.mid
      color = colors.yellow
    elseif charge > 20 then
      icon = icons.battery.low
      color = colors.peach
    else
      icon = icons.battery.empty
      color = colors.red
    end

    battery:set({
      icon = { string = icon, color = color },
      label = { string = charge .. "%" },
    })
  end)
end

battery:subscribe({ "routine", "power_source_change", "system_woke" }, update)
