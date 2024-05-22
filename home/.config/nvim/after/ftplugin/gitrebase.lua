local map = require("mapper")
local ncmd = map.ncmd
local vcmd = map.vcmd
local bufnr = 0

ncmd("gc", "Cycle", nil, bufnr)
ncmd("gp", "Pick", nil, bufnr)
ncmd("ge", "Edit", nil, bufnr)
ncmd("gf", "Fixup", nil, bufnr)
ncmd("gd", "Drop", nil, bufnr)
ncmd("gs", "Squash", nil, bufnr)
ncmd("gr", "Reword", nil, bufnr)

vcmd("gc", "Cycle", nil, bufnr)
vcmd("gp", "Pick", nil, bufnr)
vcmd("ge", "Edit", nil, bufnr)
vcmd("gf", "Fixup", nil, bufnr)
vcmd("gd", "Drop", nil, bufnr)
vcmd("gs", "Squash", nil, bufnr)
vcmd("gr", "Reword", nil, bufnr)
