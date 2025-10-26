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

tether.tick = function()
  local socket = vim.v.servername

  local err = require("tether.data"):tick(socket)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
end

---@param socket string
---@param detach? boolean
tether.switch = function(socket, detach)
  vim.api.nvim_cmd({ cmd = "connect", args = { socket }, bang = detach }, {})
end

---@param note? string
tether.note = function(note)
  local socket = vim.v.servername

  if not note then
    return vim.ui.input({ prompt = "note: " }, function(input)
      if not input then
        return
      end
      tether.note(input)
    end)
  end

  local err = require("tether.data"):note(socket, note)
  if err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
end

-- most recent first
tether.print = function()
  local iter = require("tether.data"):sorted_iter()

  vim.api.nvim_echo(
    iter:fold({}, function(acc, item)
      table.insert(acc, { item[1] .. ": ", "NonText" })
      table.insert(acc, { item[2].dir, "Directory" })
      if item[2].note and #item[2].note > 0 then
        table.insert(acc, { " " .. item[2].note })
      end
      table.insert(acc, { "\n" })
      return acc
    end),
    false,
    {}
  )
end

---@param detach? boolean
tether.select = function(detach)
  local iter = require("tether.data"):sorted_iter()
  local lst = iter:totable()
  if #lst == 0 then
    vim.notify("no servers", vim.log.levels.INFO)
    return
  end

  vim.ui.select(lst, {
    prompt = "select server",
    format_item = function(item)
      return (item[1] == vim.v.servername and "[current] " or "")
        .. item[1]
        .. ": "
        .. item[2].dir
        .. (item[2].note and #item[2].note > 0 and " " .. item[2].note or "")
    end,
  }, function(_, idx)
    local item = lst[idx]
    if not item or type(item) ~= "table" or #item == 0 then
      return
    end

    local socket = item[1]

    vim.schedule(function()
      tether.switch(socket, detach)
    end)
  end)
end

---@param detach? boolean
tether.last = function(detach)
  local last = require("tether.data"):sorted_iter():find(function(item)
    return item[1] and item[1] ~= vim.v.servername
  end)
  if not last or not last[1] then
    vim.notify("no last server", vim.log.levels.ERROR)
    return
  end

  tether.switch(last[1], detach)
end

tether.init = function()
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
      require("tether").note(fargs:peek() and table.concat(fargs:totable(), " "))
    elseif cmd == "last" then
      require("tether").last(args.bang)
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
        "last",
      }
    end,
  })
end

return tether
