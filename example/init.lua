function require_verbose(path)
    local import, err = require(path)

    if err then
        error(err)
    end
    return import
end

local theme = {
    colors = {
        error = { 0.87058, 0.10196, 0.10196, 1 },
        input = { 1, 1, 1, 1 },
        output = { 0.97647, 0.70980, 0.13333, 1 },
    }
}

local states = {
    ipAddress = "127.0.0.1",
    port = 2077,
    socket = nil,
    visible = false,
    error = nil,
    command = "",
    console = {}
}

local function onCommand(command)
    table.insert(states.console, "> " .. command)
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
    states.command = ""
end

registerForEvent('onOverlayOpen', function() states.visible = true end)
registerForEvent('onOverlayClose', function() states.visible = false end)

local function drawSettings(width, height)
    ImGui.TextDisabled("SETTINGS")
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.AlignTextToFramePadding()
    ImGui.Text("IP Address:")
    ImGui.SameLine(140)
    local ipAddress = ImGui.InputTextWithHint("##ipAddress", "127.0.0.1", states.ipAddress, 17)
    if #ipAddress >= 7 and #ipAddress <= 16 then
        states.ipAddress = ipAddress
    end

    ImGui.AlignTextToFramePadding()
    ImGui.Text("Port:")
    ImGui.SameLine(140)
    local port = ImGui.InputInt("##port", states.port, 1, 10)
    if port >= 1024 and port <= 49151 then
        states.port = port
    end
end

local function drawSocket(width, height)
    ImGui.TextDisabled("SOCKET")
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.AlignTextToFramePadding()
    local state = isConnected()
    local status = "offline"
    local action = "Connect"
    if state then
        status = "online"
        action = "Disconnect"
    end
    ImGui.Text("Status: " .. status)
    ImGui.SameLine(140)

    if ImGui.Button(action, -1, 0) then
        if not state then
            connect()
        else
            disconnect()
        end
    end

    if states.error ~= nil then
        ImGui.AlignTextToFramePadding()
        local color = theme.colors.error
        ImGui.PushStyleColor(ImGuiCol.Text, color[1], color[2], color[3], color[4])
        ImGui.TextWrapped(states.error)
        ImGui.PopStyleColor()
    end
end

local function drawConsole(width, height)
    ImGui.TextDisabled("CONSOLE")
    ImGui.Separator()
    ImGui.Spacing()

    ImGui.AlignTextToFramePadding()
    ImGui.Text("Command:")
    ImGui.SameLine(140)

    ImGui.PushItemWidth((width - 140) - 24)
    states.command = ImGui.InputText("##command", states.command, 1024)
    ImGui.PopItemWidth()
    ImGui.SameLine()
    if ImGui.ArrowButton("Button", ImGuiDir.Right) or ImGui.IsKeyReleased(ImGuiKey.Enter) then
        sendCommand()
    end
    if ImGui.IsItemHovered() then
        ImGui.SetTooltip("Send command")
    end

    ImGui.Spacing()

    if ImGui.BeginChild("##console", 0, 0, true, ImGuiWindowFlags.HorizontalScrollbar) then
        for _, command in ipairs(states.console) do
            local color = {}

            if command:find("^%$") ~= nil then
                color = theme.colors.input
            else
                color = theme.colors.output
            end
            ImGui.TextColored(color[1], color[2], color[3], color[4], command)
        end
        ImGui.EndChild()
    end
end

registerForEvent('onDraw', function()
    if not states.visible then
        return
    end
    ImGui.PushStyleVar(ImGuiStyleVar.WindowMinSize, 380, 320)
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
