local colors = require("colors")
local icons = require("icons")

local volume_icon = sbar.add("item", "volume", {
  position = "right",
  icon = {
    string = icons.volume.high,
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

-- Volume popup slider (10 segments)
local volume_slider = sbar.add("slider", "volume_slider", 100, {
  position = "popup.volume",
  width = 150,
  padding_left = 6,
  padding_right = 6,
  slider = {
    highlight_color = colors.blue,
    background = {
      height = 6,
      corner_radius = 3,
      color = colors.surface2,
    },
    knob = {
      drawing = true,
      string = "●",
      font = { family = "Hack Nerd Font", size = 18 },
      color = colors.blue,
    },
  },
  background = {
    drawing = true,
    color = colors.base,
    corner_radius = 10,
    height = 30,
  },
  click_script = 'osascript -e "set volume output volume $PERCENTAGE"',
})

local function update_volume()
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

    volume_icon:set({
      icon = { string = icon, color = color },
      label = { string = vol .. "%" },
    })
    volume_slider:set({ slider = { percentage = vol } })
  end)
end

volume_icon:subscribe("volume_change", update_volume)
volume_icon:subscribe({ "forced", "routine" }, update_volume)

-- Toggle popup on click
volume_icon:subscribe("mouse.clicked", function()
  volume_icon:set({ popup = { drawing = "toggle" } })
end)

-- Hide popup when mouse exits
volume_icon:subscribe("mouse.exited.global", function()
  volume_icon:set({ popup = { drawing = false } })
end)
