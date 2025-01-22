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
  ---@return Socket
  createSocket = function()
    local socket = RedSocket:new()

    table.insert(sockets, socket)
    return socket
  end
}

registerForEvent('onShutdown', function()
  for _, socket in ipairs(sockets) do
    socket:Disconnect()
  end
end)

return api