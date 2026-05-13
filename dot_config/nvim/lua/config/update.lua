-- Headless update orchestrator. Invoked from the justfile via:
--   nvim --headless +'lua require("config.update").run()'
--
-- Cleans orphan plugins, applies plugin updates without prompting, then
-- runs :MasonToolsUpdateSync (blocking variant intended for headless use).

local M = {}

local function orphan_names()
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

function M.run()
  local orphans = orphan_names()
  if #orphans > 0 then
    print(
      ("[pack] removing %d orphan(s): %s"):format(
        #orphans,
        table.concat(orphans, ", ")
      )
    )
    vim.pack.del(orphans)
  end

  print("[pack] updating plugins…")
  vim.pack.update(nil, { force = true })

  print("[mason] updating tools…")
  vim.cmd("MasonToolsUpdateSync")

  vim.cmd("qa!")
end

return M
