local colors = require("colors")
local icons = require("icons")

-- ── Bar appearance ───────────────────────────────────────────────────────────
sbar.bar({
  height = 36,
  color = colors.bar.bg,
  border_width = 0,
  shadow = true,
  sticky = true,
  padding_right = 12,
  padding_left = 12,
  topmost = "window",
  font_smoothing = true,
  y_offset = 6,
  margin = 10,
  corner_radius = 12,
  blur_radius = 30,
  notch_width = 200,
})

-- ── Defaults ─────────────────────────────────────────────────────────────────
sbar.default({
  updates = "when_shown",
  icon = {
    font = {
      family = "Hack Nerd Font",
      style = "Bold",
      size = 14.0,
    },
    color = colors.text,
    padding_left = 8,
    padding_right = 4,
  },
  label = {
    font = {
      family = "SF Pro",
      style = "Semibold",
      size = 13.0,
    },
    color = colors.text,
    padding_left = 4,
    padding_right = 8,
  },
  background = {
    height = 28,
    corner_radius = 8,
    color = colors.surface1,
    border_width = 0,
  },
  popup = {
    background = {
      border_width = 2,
      corner_radius = 12,
      border_color = colors.surface2,
      color = colors.base,
      shadow = { drawing = true },
    },
    blur_radius = 30,
  },
  padding_left = 4,
  padding_right = 4,
  scroll_texts = true,
})

-- Load items
require("items")
