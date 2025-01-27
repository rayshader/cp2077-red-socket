function require_verbose(path)
  local import, err = require(path)

  if err then
    error(err)
  end
  return import
end

local RedSocket = require_verbose("RedSocket")
local sockets = {}
local api = {
  ---@return RedSocket
  createSocket = function()
    local socket = RedSocket:new()

    table.insert(sockets, socket)
    return socket
  end,

  ---@param socket RedSocket
  destroySocket = function(socket)
    for i, item in ipairs(sockets) do
      if item == socket then
        socket:Destroy()
        table.remove(socket, i)
        return
      end
    end
  end
}

registerForEvent('onShutdown', function()
  for _, socket in ipairs(sockets) do
    socket:Disconnect()
    socket:Destroy()
  end
end)

return api
