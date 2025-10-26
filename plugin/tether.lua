if vim.g.loaded_tether then
  return
end

vim.g.loaded_tether = true

local group = vim.api.nvim_create_augroup("tether", { clear = true })

vim.api.nvim_create_autocmd({ "SessionLoadPost", "SessionWritePost", "UIEnter" }, {
  group = group,
  callback = function()
    require("tether").track()
  end,
})

vim.api.nvim_create_autocmd("DirChanged", {
  group = group,
  pattern = "global",
  callback = function()
    require("tether").track()
  end,
})

vim.keymap.set("n", "<Plug>(tether-select)", function()
  require("tether").select()
end)

if vim.v.vim_did_enter > 0 then
  require("tether").init()
  return
end

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    require("tether").init()
  end,
})
