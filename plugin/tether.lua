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
    local fargs = vim.iter(args.fargs)
    local cmd = fargs:next()
    if cmd == "track" then
      require("tether").track()
    elseif cmd == "select" then
      require("tether").select(args.bang)
    elseif cmd == "print" then
      require("tether").print()
    elseif cmd == "note" then
      require("tether").note(fargs:fold("", function(acc, v)
        return acc .. (#acc > 0 and " " or "") .. v
      end))
    else
      vim.notify("unknown command: " .. cmd, vim.log.levels.ERROR)
    end
  end, {
    nargs = "+",
    bang = true,
    complete = function()
      return {
        "track",
        "select",
        "print",
        "note",
      }
    end,
  })
end)
