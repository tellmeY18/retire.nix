local colors = require("colors")
local icons = require("icons")

local media = sbar.add("item", "media", {
  position = "center",
  icon = {
    string = icons.media,
    font = { family = "Hack Nerd Font", style = "Bold", size = 12.0 },
    color = colors.pink,
    padding_left = 10,
  },
  label = {
    font = { family = "SF Pro", style = "Medium", size = 11.0 },
    color = colors.subtext0,
    max_chars = 40,
    padding_right = 10,
  },
  background = {
    drawing = true,
    color = colors.surface1,
    corner_radius = 8,
    height = 26,
  },
  drawing = false,
  update_freq = 5,
})

media:subscribe({ "forced", "routine", "media_change", "system_woke" }, function()
  sbar.exec([[osascript -e '
    tell application "System Events"
      if (name of processes) contains "Spotify" then
        tell application "Spotify"
          if player state is playing then
            return (name of current track) & " — " & (artist of current track)
          end if
        end tell
      else if (name of processes) contains "Music" then
        tell application "Music"
          if player state is playing then
            return (name of current track) & " — " & (artist of current track)
          end if
        end tell
      end if
    end tell
    return ""
  ' 2>/dev/null]], function(result)
    if result and result ~= "" and result ~= "\n" then
      media:set({ drawing = true, label = { string = result:gsub("\n", "") } })
    else
      media:set({ drawing = false })
    end
  end)
end)
