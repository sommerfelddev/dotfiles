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
