local colors = require("colors")
local icons = require("icons")

local volume = sbar.add("item", "volume", {
  position = "right",
  icon = {
    font = { family = "Hack Nerd Font", style = "Bold", size = 14.0 },
    color = colors.sky,
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
  padding_left = 2,
  padding_right = 2,
})

local function update()
  sbar.exec("osascript -e 'set ovol to output volume of (get volume settings)\nset omut to output muted of (get volume settings)\nreturn (ovol as text) & \",\" & (omut as text)'", function(result)
    local vol_str, muted_str = result:match("(%d+),(%a+)")
    local vol = tonumber(vol_str) or 0
    local muted = muted_str == "true"

    local icon = icons.volume.high
    local color = colors.sky

    if muted or vol == 0 then
      icon = icons.volume.mute
      color = colors.red
    elseif vol > 66 then
      icon = icons.volume.high
    elseif vol > 33 then
      icon = icons.volume.mid
    else
      icon = icons.volume.low
    end

    volume:set({
      icon = { string = icon, color = color },
      label = { string = vol .. "%" },
    })
  end)
end

volume:subscribe("volume_change", update)
volume:subscribe({ "forced", "routine" }, update)
