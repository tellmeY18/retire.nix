local colors = require("colors")
local icons = require("icons")

-- Workspace switching via omniwmctl (OmniWM IPC).
-- omniwm must have IPC enabled (services.omniwm.settings.general.ipcEnabled = true).

local spaces = {}

for i = 1, 9 do
  local space = sbar.add("item", "space." .. i, {
    icon = {
      string = tostring(i),
      font = { family = "Hack Nerd Font", style = "Bold", size = 13.0 },
      color = colors.overlay0,
      padding_left = 8,
      padding_right = 0,
    },
    label = {
      string = "",
      font = { family = "sketchybar-app-font", style = "Regular", size = 14.0 },
      color = colors.overlay0,
      padding_left = 4,
      padding_right = 8,
      y_offset = -1,
    },
    background = {
      drawing = true,
      color = colors.surface0,
      corner_radius = 8,
      height = 28,
    },
    padding_left = 2,
    padding_right = 2,
    click_script = "omniwmctl command switch-workspace " .. i,
    update_freq = 3,
  })

  spaces[i] = space

  space:subscribe({ "forced", "routine" }, function()
    -- Query OmniWM for the current workspace state on this monitor.
    -- Parse JSON to find which workspace is focused and its app icons.
    sbar.exec(
      "omniwmctl query workspaces --format json 2>/dev/null || echo '[]'",
      function(result)
        local focused = false
        local icon_line = ""

        -- Try to parse JSON; on failure, do nothing.
        local ok, data = pcall(sbar.parse_json, result)
        if ok and data then
          for _, ws in ipairs(data) do
            if ws["is-current"] or ws["is-focused"] then
              if ws["number"] == i then
                focused = true
              end
            end
            if ws["number"] == i then
              local counts = ws["window-counts"] or {}
              local managed = counts["managed"] or 0
              if managed > 0 then
                icon_line = "●"
              end
            end
          end
        end

        local has_windows = icon_line ~= ""

        sbar.animate("tanh", 10, function()
          space:set({
            icon = {
              color = focused and colors.crust or (has_windows and colors.text or colors.overlay0),
            },
            label = {
              string = icon_line,
              color = focused and colors.crust or colors.subtext0,
            },
            background = {
              color = focused and colors.blue or (has_windows and colors.surface1 or colors.surface0),
            },
          })
        end)
      end
    )
  end)
end

-- Spacer between workspace groups.
sbar.add("item", "space_sep", {
  icon = { drawing = false },
  label = { drawing = false },
  background = { drawing = false },
  padding_left = 4,
  padding_right = 4,
})
