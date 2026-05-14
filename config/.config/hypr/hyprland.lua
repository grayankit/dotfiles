--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--
-- -----------------------------------------------------
-- Full documentation https://wiki.hyprland.org

-- Ensure the 'conf' directory is in the package path so require() works natively
local config_dir = os.getenv("HOME") .. "/.config/hypr/"
package.path = package.path .. ";" .. config_dir .. "?.lua"

require("conf.monitor")
require("conf.autostart")
require("conf.cursor")
require("conf.environments")
require("conf.input")
require("conf.general")
require("conf.decoration")
require("conf.animations")
require("conf.layouts")
require("conf.gestures")
require("conf.misc")
require("conf.windowrules")
require("conf.binds")
require("conf.experimental")
require("conf.plugins")
