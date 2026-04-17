local overseer = require("overseer")
overseer.setup({})
overseer.add_template_hook({ name = ".*" }, function(task_defn, util)
  util.add_component(task_defn, {
    "open_output",
    on_start = "never",
    on_complete = "failure",
    direction = "vertical",
  })
end)

vim.keymap.set("n", "<leader>to", function()
  overseer.toggle()
end, { desc = "[T]oggle [O]verseer" })
vim.keymap.set("n", "<leader>ob", function()
  overseer.run_task({ name = "just build", disallow_prompt = true })
end, { desc = "[O]verseer [B]uild" })
vim.keymap.set("n", "<leader>oB", function()
  overseer.run_task({ name = "just build" })
end, { desc = "[O]verseer [B]uild" })
vim.keymap.set("n", "<leader>ot", function()
  overseer.run_task({ name = "just test", disallow_prompt = true })
end, { desc = "[O]verseer [J]ust [T]est" })
vim.keymap.set("n", "<leader>oT", function()
  overseer.run_task({ name = "just test" })
end, { desc = "[O]verseer [J]ust [T]est" })
vim.keymap.set("n", "<leader>of", function()
  overseer.run_task({
    name = "just test",
    disallow_prompt = true,
    params = { target = vim.fn.expand("%") },
  })
end, { desc = "[O]verseer test [F]ile" })
vim.keymap.set("n", "<leader>oF", function()
  overseer.run_task({
    name = "just test",
    params = { target = vim.fn.expand("%") },
  })
end, { desc = "[O]verseer test [F]ile" })
vim.keymap.set("n", "<leader>od", function()
  overseer.run_task({
    name = "just debug=true test",
    disallow_prompt = true,
    params = { target = vim.fn.expand("%") },
  })
end, { desc = "[O]verseer [d]ebug test file" })
vim.keymap.set("n", "<leader>oD", function()
  overseer.run_task({
    name = "just debug=true test",
    params = { target = vim.fn.expand("%") },
  })
end, { desc = "[O]verseer [D]ebug test file" })
vim.keymap.set("n", "<leader>oa", function()
  overseer.run_task({
    name = "just test_autofix",
    disallow_prompt = true,
    params = { target = vim.fn.expand("%") },
  })
end, { desc = "[O]verseer [A]utofix" })
vim.keymap.set("n", "<leader>or", function()
  overseer.run_task()
end, { desc = "[O]verseer [R]un" })
vim.keymap.set("n", "<leader>os", function()
  vim.cmd("OverseerShell")
end, { desc = "[O]verseer [S]hell" })
vim.keymap.set("n", "<leader>ol", function()
  local tasks = overseer.list_tasks({
    sort = function(a, b)
      return a.id > b.id
    end,
  })
  if vim.tbl_isempty(tasks) then
    vim.notify("No tasks found", vim.log.levels.WARN)
  else
    overseer.run_action(tasks[1], "restart")
  end
end, { desc = "[O]verseer run [L]ast" })
