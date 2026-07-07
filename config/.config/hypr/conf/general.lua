local status, colors = pcall(require, "conf.colors")
if not status then
    colors = {
        active = { colors = { "rgba(186,52,68,1.000)", "rgba(127,47,55,1.000)" }, angle = 45 },
        inactive = "rgba(595959aa)"
    }
end

hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 2,
        border_size = 2,
        ["col.active_border"] = colors.active,
        ["col.inactive_border"] = colors.inactive,
        layout = "dwindle",
        resize_on_border = true
    }
})
