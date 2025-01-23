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
        table.remove(socket, i)
      end
    end
  end
}

registerForEvent('onShutdown', function()
  for _, socket in ipairs(sockets) do
    socket:Disconnect()
  end
end)

return api