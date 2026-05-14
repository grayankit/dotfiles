-- NOTE: For floating vesktop
-- hl.window_rule({ match = { class = "^(vesktop)$" }, float = true })
-- hl.window_rule({ match = { class = "^(vesktop)$" }, size = { 1600, 1000 } })
-- hl.window_rule({ match = { class = "^(vesktop)$" }, center = true })
-- hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = "special:discord" })

-- NOTE: For Obsidian floating
-- hl.window_rule({ match = { class = "^(obsidian)$" }, float = true })
-- hl.window_rule({ match = { class = "^(obsidian)$" }, size = { 1400, 900 } })
-- hl.window_rule({ match = { class = "^(obsidian)$" }, center = true })
-- hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = "special:notes" })

hl.window_rule({
    name = "pwvucontrol",
    match = { class = "com.saivert.pwvucontrol" },
    float = true,
    size = { 1200, 800 },
    center = true
})

hl.window_rule({
    name = "spotify",
    match = { class = "^([sS]potify)$" },
    float = true,
    size = { 1200, 800 },
    center = true
})
