-- Load all bar items.
-- Order matters: left items first, then center, then right.

-- LEFT
require("items.apple")
require("items.spaces")
require("items.front_app")

-- CENTER
require("items.media")

-- RIGHT (rightmost added first)
require("items.calendar")
require("items.battery")
require("items.volume")
require("items.wifi")
require("items.memory")
require("items.cpu")
