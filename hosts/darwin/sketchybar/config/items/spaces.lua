local colors = require("colors")
local icons = require("icons")

-- Register the custom event that AeroSpace fires on workspace change.
sbar.add("event", "aerospace_workspace_change")

local spaces = {}

for i = 1, 10 do
  local space = sbar.add("item", "space." .. i, {
    icon = { drawing = false },
    label = {
      string = tostring(i),
      font = { family = "Hack Nerd Font", style = "Bold", size = 13.0 },
      color = colors.overlay0,
      padding_left = 10,
      padding_right = 10,
    },
    background = {
      drawing = true,
      color = colors.surface0,
      corner_radius = 8,
      height = 28,
    },
    padding_left = 2,
    padding_right = 2,
    click_script = "aerospace workspace " .. i,
  })

  spaces[i] = space

  space:subscribe("aerospace_workspace_change", function(env)
    local focused = env.FOCUSED_WORKSPACE == tostring(i)
    space:set({
      label = { color = focused and colors.crust or colors.overlay0 },
      background = { color = focused and colors.blue or colors.surface0 },
    })
  end)
end

-- Separator between workspace groups (laptop 1-5 | monitor 6-10)
sbar.add("item", "space_separator", {
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = 4,
  padding_right = 4,
})
