local tether = {}

tether.track = function()
  local socket = vim.v.servername
  local cwd = vim.fn.getcwd()

  local err = require("tether.data"):register(socket, cwd)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
end

tether.print = function()
  local iter = require("tether.data"):iter()

  vim.print(iter:fold("", function(acc, k, v)
    return acc .. k .. ": " .. v .. "\n"
  end))
end

---@param detach? boolean
tether.select = function(detach)
  local iter = require("tether.data"):iter()
  local lst = iter:totable()
  if #lst == 0 then
    vim.notify("no servers", vim.log.levels.INFO)
    return
  end

  vim.ui.select(
    vim
      .iter(ipairs(lst))
      :map(function(_, item)
        return (item[1] == vim.v.servername and "[current] " or "") .. item[1] .. ": " .. item[2]
      end)
      :totable(),
    { prompt = "select server" },
    function(_, idx)
      local item = lst[idx]
      if not item then
        return
      end

      local socket = item[1]

      vim.schedule(function()
        vim.api.nvim_cmd({ cmd = "connect", args = { socket }, bang = detach }, {})
      end)
    end
  )
end

return tether
