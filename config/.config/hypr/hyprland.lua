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

-- DankMaterialShell fragments (deployed by `dms setup <name>`).
-- These are required LAST so DMS owns gaps, radius and border colors.
-- NOTE: require("dms.outputs") is deliberately NOT included — conf/monitor.lua
-- is authoritative for eDP-1 ICC + DP-1 10-bit/sRGB rules, and dms/outputs.lua
-- ships a catch-all `mode=preferred` rule that would clobber them.
-- colors.lua is generated on the first matugen run and gitignored, so a fresh
-- stow has no file yet. A bare require would abort this script and skip the
-- layout + windowrules requires below.
-- layout.lua and windowrules.lua are DMS-generated and gitignored, same as
-- colors.lua. Missing files must not abort the rest of this script.
pcall(require, "dms.colors")
pcall(require, "dms.layout")
pcall(require, "dms.windowrules")
