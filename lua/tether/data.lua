---@class tether.Data
local Data = {}
Data.__index = Data

function Data:new()
  return setmetatable({}, Data)
end

local filepath = vim.fs.joinpath(vim.fn.stdpath("state"), "tether.json")

---@return string? err
---@nodiscard
function Data:read()
  local file = io.open(filepath, "r")
  if not file then
    return "could not open file: " .. filepath
  end
  local contents = file:read("*a")

  local json = vim.json.decode(contents)
  if type(json) ~= "table" then
    return "malformed data"
  end

  for k, v in pairs(json) do
    if type(k) == "string" and type(v) == "string" then
      local stat = vim.uv.fs_stat(k)
      if stat ~= nil and stat.type == "socket" then
        rawset(self, k, v)
      end
    end
  end
end

function Data:clean()
  vim
    .iter(pairs(self))
    :filter(function(k)
      return k ~= "__metatable"
    end)
    :filter(function(k, _)
      local stat = vim.uv.fs_stat(k)
      return not (stat ~= nil and stat.type == "socket")
    end)
    :each(function(k, _)
      rawset(self, k, nil)
    end)
end

---@return string? err
---@nodiscard
function Data:write()
  local file = io.open(filepath, "w+")
  if not file then
    return "could not open file: " .. filepath
  end

  self:clean()
  local contents = vim.json.encode(self)
  file:write(contents)
  file:close()
end

---@param socket string
---@param wd string
---@return string? err
---@nodiscard
function Data:register(socket, wd)
  local _ = self:read()
  -- ignore

  rawset(self, socket, wd)

  local err = self:write()
  if err then
    return err
  end
end

---@return Iter
function Data:iter()
  local _ = self:read()
  -- ignore
  self:clean()

  return vim.iter(pairs(self)):filter(function(k)
    return k ~= "__metatable"
  end)
end

local data = Data:new()

return data
