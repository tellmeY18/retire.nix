local colors = require("colors")
local icons = require("icons")

local wifi = sbar.add("item", "wifi", {
  position = "right",
  icon = {
    string = icons.wifi.off,
    font = { family = "Hack Nerd Font", style = "Bold", size = 14.0 },
    color = colors.teal,
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
  update_freq = 10,
  padding_left = 2,
  padding_right = 2,
})

local function update()
  sbar.exec("ipconfig getsummary en0 2>/dev/null || echo ''", function(info)
    local connected = info:find("AirPort") ~= nil or info:find("LinkStatusActive : TRUE") ~= nil
    local ssid = info:match("SSID%s*:%s*(.-)%s*\n") or ""

    if connected and ssid ~= "" then
      wifi:set({
        icon = { string = icons.wifi.on, color = colors.teal },
        label = { string = ssid },
      })
    else
      wifi:set({
        icon = { string = icons.wifi.off, color = colors.overlay0 },
        label = { string = "" },
      })
    end
  end)
end

wifi:subscribe({ "forced", "routine", "wifi_change" }, update)
