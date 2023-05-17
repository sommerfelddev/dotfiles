local M = {}

M.map = function(mode, keys, action, opts, bufnr)
  opts = vim.tbl_extend("force", { silent = true, buffer = bufnr }, opts or {})
  vim.keymap.set(mode, keys, action, opts)
end

M.cmdi = function(mode, keys, action, opts, bufnr)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})
  M.map(mode, keys, ":" .. action, opts, bufnr)
end

M.cmd = function(mode, keys, action, opts, bufnr)
  M.map(mode, keys, "<cmd>" .. action .. "<cr>", opts, bufnr)
end

M.plug = function(mode, keys, action, opts, bufnr)
  M.map(mode, keys, "<Plug>" .. action, opts, bufnr)
end

M.n = function(keys, action, opts, bufnr)
  M.map("n", keys, action, opts, bufnr)
end
M.ncmdi = function(keys, action, opts, bufnr)
  M.cmdi("n", keys, action, opts, bufnr)
end
M.ncmd = function(keys, action, opts, bufnr)
  M.cmd("n", keys, action, opts, bufnr)
end
M.nplug = function(keys, action, opts, bufnr)
  M.plug("n", keys, "(" .. action .. ")", opts, bufnr)
end

M.v = function(keys, action, opts, bufnr)
  M.map("v", keys, action, opts, bufnr)
end
M.vcmdi = function(keys, action, opts, bufnr)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})
  M.v(keys, ":" .. action, opts, bufnr)
end
M.vcmd = function(keys, action, opts, bufnr)
  M.vcmdi(keys, action .. "<cr>", opts, bufnr)
end
M.vplug = function(keys, action, opts, bufnr)
  M.plug("v", keys, "(" .. action .. ")", opts, bufnr)
end

M.nv = function(keys, action, opts, bufnr)
  M.map({ "n", "v" }, keys, action, opts, bufnr)
end
M.nvcmdi = function(keys, action, opts, bufnr)
  M.ncmdi(keys, action, opts, bufnr)
  M.vcmdi(keys, action, opts, bufnr)
end
M.nvcmd = function(keys, action, opts, bufnr)
  M.ncmd(keys, action, opts, bufnr)
  M.vcmd(keys, action, opts, bufnr)
end
M.nvplug = function(keys, action, opts, bufnr)
  M.plug({ "n", "v" }, keys, "(" .. action .. ")", opts, bufnr)
end

M.i = function(keys, action, opts, bufnr)
  M.map("i", keys, action, opts, bufnr)
end
M.iplug = function(keys, action, opts, bufnr)
  opts = vim.tbl_extend("force", { silent = false }, opts or {})
  M.plug("i", keys, action, opts, bufnr)
end

M.t = function(keys, action, opts, bufnr)
  M.map("t", keys, action, opts, bufnr)
end
M.tcmdi = function(keys, action, opts, bufnr)
  M.cmdi("t", keys, action, opts, bufnr)
end
M.tcmd = function(keys, action, opts, bufnr)
  M.cmd("t", keys, action, opts, bufnr)
end
M.tplug = function(keys, action, opts, bufnr)
  M.plug("t", keys, action, opts, bufnr)
end

return M
