---@class RedSocket
---
---@field socket any?
---@field proxy any?
local RedSocket = {}

function RedSocket:new()
  local obj = {}
  setmetatable(obj, { __index = RedSocket })

  obj.socket = Socket.new()
  obj.proxy = nil
  return obj
end

---@return boolean
function RedSocket:IsConnected()
  return self.socket:IsConnected()
end

---@param onCommand function callback when a command is received
---@param onDisconnection function? optional callback to detect disconnection
function RedSocket:RegisterListener(onCommand, onDisconnection)
  if onCommand == nil then
    return
  end
  self.proxy = NewProxy({
    ["OnCommand"] = {
      args = {"String"},
      callback = function(command) onCommand(command) end,
    },
    ["OnDisconnection"] = {
      args = {},
      callback = function()
        if onDisconnection ~= nil then
          onDisconnection()
        end
      end,
    }
  })
  self.socket:RegisterListener(self.proxy:Target(),
                               self.proxy:Function("OnCommand"),
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
function RedSocket:SendCommand(command)
  self.socket:SendCommand(command)
end

return RedSocket