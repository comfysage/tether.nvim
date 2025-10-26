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
    if type(k) == "string" and type(v) == "table" then
      local stat = vim.uv.fs_stat(k)
      if stat ~= nil and stat.type == "socket" then
        rawset(self, k, v)
      end
    end
  end
end

function Data:clean()
  self
    :_iter()
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

---@param fn function
---@return string? err
---@nodiscard
function Data:updatewrap(fn)
  local _ = self:read()
  -- ignore

  do
    local ok, result = pcall(fn)
    if not ok then
      return result
    end
  end

  do
    local err = self:write()
    if err then
      return err
    end
  end
end

---@param socket string
---@param wd string
---@return string? err
---@nodiscard
function Data:register(socket, wd)
  return self:updatewrap(function()
    rawset(self, socket, { dir = wd, tick = os.time() })
  end)
end

---@param socket string
---@return string? err
---@nodiscard
function Data:tick(socket)
  return self:updatewrap(function()
    local prev = rawget(self, socket)
    rawset(self, socket, { dir = prev.dir, tick = os.time() })
  end)
end

---@private
---@return Iter
function Data:_iter()
  return vim.iter(pairs(self)):filter(function(k)
    return k ~= "__metatable"
  end)
end

---@return Iter
function Data:iter()
  local _ = self:read()
  -- ignore
  self:clean()

  return self:_iter()
end

local function sortitems(a, b)
  if not b or not b.tick then
    return true
  end
  if not a or not a.tick then
    return false
  end
  return a.tick > b.tick
end

---@return Iter
function Data:sorted_iter()
  local iter = self:iter()
  local lst = iter:totable()
  table.sort(lst, function(a, b)
    return sortitems(a[2], b[2])
  end)
  return vim.iter(lst)
end

local data = Data:new()

return data
