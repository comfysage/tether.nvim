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

vim.schedule(function()
  vim.api.nvim_create_user_command("Tether", function(args)
    if args.fargs[1] == "track" then
      require("tether").track()
      return
    elseif args.fargs[1] == "select" then
      require("tether").select(args.bang)
      return
    elseif args.fargs[1] == "print" then
      require("tether").print()
    end
  end, {
    nargs = "+",
    bang = true,
    complete = function()
      return {
        "track",
        "select",
        "print",
      }
    end,
  })
end)
