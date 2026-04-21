vim.filetype.add({
  extension = {
    eml = "mail",
    inc = "cpp",
    def = "cpp",
    Jenkinsfile = "groovy",
  },
  filename = {
    [".devcontainer.json"] = "jsonc",
  },
  pattern = {
    [".*/.github/workflows/.*%.ya?ml"] = "yaml.ghaction",
  },
})
