local function nvmap(l, r, desc)
  vim.keymap.set(
    { "n", "v" },
    l,
    ":" .. r .. "<CR>",
    { buffer = 0, desc = "[G]it rebase " .. desc }
  )
end

nvmap("gc", "Cycle", "[C]ycle")
nvmap("gp", "Pick", "[P]ick")
nvmap("ge", "Edit", "[E]dit")
nvmap("gf", "Fixup", "[F]ixup")
nvmap("gd", "Drop", "[D]rop")
nvmap("gs", "Squash", "[S]quash")
nvmap("gr", "Reword", "[R]eword")
