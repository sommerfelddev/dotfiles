-- Update orchestrator. Invoked from the justfile via:
--   nvim +'lua require("config.update").run()'
--
-- Cleans orphan plugins then applies plugin updates without prompting.
-- Run interactively (not --headless) so the diff buffer that
-- vim.pack.update opens is actually visible — that buffer IS the
-- changelog. Quit manually with :qa once reviewed.

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
end

return M
