---@class RedSocket
---
---@field socket any?
---@field proxy any?
local RedSocket = {}

function RedSocket:new()
  local obj = {}
  setmetatable(obj, { __index = RedSocket })

  obj.socket = Socket.Create()
  obj.proxy = nil
  return obj
end

---@return boolean
function RedSocket:IsConnected()
  return self.socket:IsConnected()
end

---@param onCommand function callback when a command is received
---@param onConnection function callback when connection is opened
---@param onDisconnection function? optional callback when connection is closed
---@param onError function? optional callback when sending a command failed after too many attempts
function RedSocket:RegisterListener(onCommand, onConnection, onDisconnection, onError)
  if onCommand == nil or onConnection == nil then
    return
  end
  self.proxy = NewProxy({
    ["OnCommand"] = {
      args = {"String"},
      callback = function(command) onCommand(command) end,
    },
    ["OnConnection"] = {
      args = {"Int32"},
      callback = function(status) onConnection(status) end,
    },
    ["OnDisconnection"] = {
      args = {},
      callback = function()
        if onDisconnection ~= nil then
          onDisconnection()
        end
      end,
    },
    ["OnError"] = {
      args = {},
      callback = function()
        if onError ~= nil then
          onError()
        end
      end,
    }
  })
  self.socket:RegisterListener(self.proxy:Target(),
                               self.proxy:Function("OnCommand"),
                               self.proxy:Function("OnConnection"),
                               self.proxy:Function("OnDisconnection"))
end

---@param ipAddress string (e.g. '127.0.0.1')
---@param port integer (e.g. 2077)
function RedSocket:Connect(ipAddress, port)
  return self.socket:Connect(ipAddress, port)
end

function RedSocket:Disconnect()
  self.socket:Disconnect()
end

---@param command string it must not include `\r\n` or command will be ignored.
---@param limit integer? at least 1, default is 10 when nil.
function RedSocket:SendCommand(command, limit)
  if limit == nil then
    self.socket:SendCommand(command)
  else
    self.socket:SendCommand(command, limit, self.proxy:Target(), self.proxy:Function("OnError"))
  end
end

function RedSocket:Destroy()
  Socket.Destroy(self.socket)
end

return RedSocket