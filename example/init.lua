function require_verbose(path)
    local import, err = require(path)

    if err then
        error(err)
    end
    return import
end

local theme = {
    field = {
        width = 120,
    },
    colors = {
        success = { 0.32941, 0.86274, 0.32941, 1 },
        error = { 0.86274, 0.32941, 0.32941, 1 },
    }
}

local states = {
    ipAddress = "127.0.0.1",
    port = 2077,
    socket = nil,
    visible = false,
    error = nil,
    command = "",
    console = {},
    incoming = 0,
    outgoing = 0,
}

local function onCommand(command)
    table.insert(states.console, command)
    states.incoming = states.incoming + #command + 2
end

local function onDisconnection()
    local RedSocket = GetMod("RedSocket")

    RedSocket.destroySocket(states.socket)
    states.socket = nil
    states.command = ""
end

local function isConnected()
    if states.socket == nil then
        return false
    end
    return states.socket:IsConnected()
end

local function connect()
    if isConnected() then
        return
    end
    if states.socket == nil then
        local RedSocket = GetMod("RedSocket")

        states.socket = RedSocket.createSocket()
        states.socket:RegisterListener(onCommand, onDisconnection)
    end
    local result = states.socket:Connect(states.ipAddress, states.port)

    if not result then
        states.error = "Failed to connect on server."
    else
        states.error = nil
    end
end

local function disconnect()
    if not isConnected() then
        return
    end
    states.socket:Disconnect()
    states.error = nil
end

local function sendCommand()
    if not isConnected() then
        return
    end
    local command = states.command

    if #command == 0 then
        return
    end
    states.socket:SendCommand(command)
    table.insert(states.console, "$ " .. command)
    states.outgoing = states.outgoing + #command + 2
    states.command = ""
end

local function clearConsole()
    states.console = {}
end

registerForEvent('onOverlayOpen', function() states.visible = true end)
registerForEvent('onOverlayClose', function() states.visible = false end)

local function drawSettings(width, height)
    ImGui.TextDisabled("SETTINGS")
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.AlignTextToFramePadding()
    ImGui.Text("IP Address:")
    ImGui.SameLine(theme.field.width)
    ImGui.PushItemWidth(width - theme.field.width)
    local ipAddress = ImGui.InputTextWithHint("##ipAddress", "127.0.0.1", states.ipAddress, 17)
    ImGui.PopItemWidth()
    if #ipAddress >= 7 and #ipAddress <= 16 then
        states.ipAddress = ipAddress
    end

    ImGui.AlignTextToFramePadding()
    ImGui.Text("Port:")
    ImGui.SameLine(theme.field.width)
    ImGui.PushItemWidth(width - theme.field.width)
    ---@type any?
    local port = tostring(states.port)
    port = ImGui.InputTextWithHint("##port", "2077", port, 6, ImGuiInputTextFlags.CharsDecimal +
        ImGuiInputTextFlags.CharsNoBlank)
    ImGui.PopItemWidth()
    if port == nil or #port == 0 then
        port = 0
    else
        port = tonumber(port)
        port = math.floor(port)
    end
    if port >= 1024 and port <= 49151 then
        states.port = port
    end
end

local function drawSocket(width, height)
    local color = {}

    ImGui.TextDisabled("SOCKET")
    ImGui.Separator()
    ImGui.Spacing()

    local state = isConnected()
    local status = "offline"
    local action = "Connect"
    color = theme.colors.error

    if state then
        status = "online"
        action = "Disconnect"
        color = theme.colors.success
    end
    ImGui.AlignTextToFramePadding()
    ImGui.Text("Status:")
    ImGui.SameLine()
    ImGui.TextColored(color[1], color[2], color[3], color[4], status)
    ImGui.SameLine(theme.field.width)

    if ImGui.Button(action, -1, 0) then
        if not state then
            connect()
        else
            disconnect()
        end
    end

    if states.error ~= nil then
        ImGui.AlignTextToFramePadding()
        color = theme.colors.error
        ImGui.PushStyleColor(ImGuiCol.Text, color[1], color[2], color[3], color[4])
        ImGui.TextWrapped(states.error)
        ImGui.PopStyleColor()
    end

    ImGui.AlignTextToFramePadding()
    ImGui.Text(string.format("Incoming: %d bytes", states.incoming))

    ImGui.AlignTextToFramePadding()
    ImGui.Text(string.format("Outgoing: %d bytes", states.outgoing))
end

local function drawConsole(width, height)
    ImGui.TextDisabled("CONSOLE")
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.PushItemWidth(width - 2 * 24)
    states.command = ImGui.InputText("##command", states.command, 1024)
    ImGui.PopItemWidth()

    ImGui.SameLine()

    if ImGui.ArrowButton("Button", ImGuiDir.Right) or ImGui.IsKeyReleased(ImGuiKey.Enter) then
        sendCommand()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Send command")
    end

    ImGui.SameLine()

    if ImGui.Button(" X ") then
        clearConsole()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Clear console")
    end

    ImGui.Spacing()

    if ImGui.BeginChild("##console", 0, 0, true, ImGuiWindowFlags.HorizontalScrollbar) then
        for _, command in ipairs(states.console) do
            ImGui.Text(command)
        end
        ImGui.EndChild()
    end
end

registerForEvent('onDraw', function()
    if not states.visible then
        return
    end
    ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, 280, 320)
    if not ImGui.Begin("RedSocket") then
        ImGui.End()
        return
    end
    local width, height = ImGui.GetContentRegionAvail()

    drawSettings(width, height)

    ImGui.Dummy(0, 12)

    drawSocket(width, height)

    ImGui.Dummy(0, 12)

    drawConsole(width, height)

    ImGui.End()
end)

registerForEvent('onShutdown', function()
    if states.socket ~= nil then
        states.socket:Disconnect()
    end
end)
