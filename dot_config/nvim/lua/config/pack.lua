-- User commands wrapping vim.pack for ergonomic update/clean/sync workflows.

local function orphans()
  return vim
    .iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable()
end

local function clean()
  local names = orphans()
  if #names == 0 then
    vim.notify("no orphan plugins", vim.log.levels.INFO)
    return
  end
  vim.pack.del(names)
end

local function update()
  vim.pack.update(nil, { force = true })
end

local function list()
  local plugs = vim.pack.get()
  table.sort(plugs, function(a, b)
    return a.spec.name < b.spec.name
  end)
  local lines = {}
  for _, p in ipairs(plugs) do
    local mark = p.active and "●" or "○"
    local ver = p.spec.version
    if type(ver) == "table" then
      ver = tostring(ver)
    end
    table.insert(
      lines,
      string.format(
        "%s %-40s %-12s %s",
        mark,
        p.spec.name,
        (p.rev or ""):sub(1, 8),
        ver or ""
      )
    )
  end
  vim.api.nvim_echo(
    vim.tbl_map(function(l)
      return { l .. "\n" }
    end, lines),
    false,
    {}
  )
end

vim.api.nvim_create_user_command("PackClean", clean, {
  desc = "Remove plugins not declared in vim.pack.add()",
})

vim.api.nvim_create_user_command("PackUpdate", update, {
  desc = "Update all plugins without confirmation",
})

vim.api.nvim_create_user_command("PackSync", function()
  clean()
  update()
end, {
  desc = "Clean orphan plugins then update the rest",
})

vim.api.nvim_create_user_command("PackList", list, {
  desc = "List managed plugins (● active, ○ orphan)",
})
