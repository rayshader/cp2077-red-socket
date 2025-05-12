# RedSocket

![Cyberpunk 2077](https://img.shields.io/badge/Cyberpunk%202077-v2.21-blue)
![GitHub License](https://img.shields.io/github/license/rayshader/cp2077-red-socket)
[![Donate](https://img.shields.io/badge/donate-buy%20me%20a%20coffee-yellow)](https://www.buymeacoffee.com/lpfreelance)

This plugin allows to connect to a remote TCP server. It is mainly intended for
research purpose. It allows to read and write commands. As an example, it can
be used with a debugger (with its own server script plugin) to send commands 
(e.g. to add breakpoints, watch values, ...). It includes an easy-to-use API for
CET.

> [!IMPORTANT]  
> This implementation is not secure and don't provide any kind of security when
> sending and reading messages. Only use this tool at your own risks, with your
> own TCP server on a local network.

# Getting started

## Compatibility
- Cyberpunk 2077 v2.21
- [RED4ext] v1.27.0+
- [Redscript] 0.5.27+
- [Cyber Engine Tweaks] 1.35.0+

## Installation
1. Install requirements:
- [RED4ext] v1.27.0+
- [Cyber Engine Tweaks] 1.35.0+

2. Extract the [latest archive] into the Cyberpunk 2077 directory.

## Demo

![Screenshot of CET example](demo.png)

(see /examples/init.lua for reference, or copy into {GAME_DIR}/bin/x64/plugins/cyber_engine_tweaks/mods/{YOUR_MOD} to use)

## Usage

This plugin can be used with redscript and CET. It allows any length of commands
to be sent and received.

> [!NOTE]  
> Don't include `\r\n` in a command, it is used internally. If you do, command
> will be ignored.

### Redscript

You need to create a `RedSocket.Socket`:
```swift
import RedSocket.*

let socket: ref<Socket> = Socket.Create();
```

> [!NOTE]  
> Creating a socket with `new Socket()` will not work. Only the method above can
> be used in order to poll events of the socket in background.

Register listener with callbacks for commands/connection/disconnection.
```swift
let object: ref<IScriptable>;

socket.RegisterListener(object, n"OnCommand", n"OnConnection", n"OnDisconnection");
```

> [!NOTE]  
> You must register a listener before calling `Connect`. Any attempts of 
> connection without a listener will be ignored.
> 
> Last argument is optional, declare it if you want to be notified when 
> connection is closed by the remote server.

Connect to a server:
```swift
socket.Connect("127.0.0.1", 2077);

// in class of `object` above
public cb func OnConnection(status: Int32) {
    if status != 0 {
        FTLogError(s"Failed to connect on 127.0.0.1:2077");
        // See in red4ext/logs/ for more details.
        return;
    }
    FTLog(s"Ready to read/write commands.");
}
```

Send a message:
```swift
socket.SendCommand("chat Hello world!");
```

You can optionally provide a callback to know when a command failed to send.
By default, it will retry up to 10 times until the entire message is sent.
A minimum of 1 failed attempt is allowed, any value below will default to 10.
```swift
socket.SendCommand("<big chunk>", 5, this, n"OnError");
//                                ^  ^     ^
//                                |  |     | method to call with `cb` keyword
//                                |  |
//                                |  | object to call the method on
//                                |
//                                | maximum attempts before aborting and 
//                                  triggering error callback

public cb func OnError() {
    FTLogError(s"Failed to send command after 5 attempts. Try again...");
}
```

If the remote socket is closed while trying to send a command, error callback
will not be triggered, but `onDisconnection` will.

Your callback for incoming commands will be executed when commands are fully
received.
```swift
// in class of `object` above
public cb func OnCommand(command: String) {
    FTLog(s"Received command: \(command)");
}
```

Disconnect from the server:
```swift
socket.Disconnect();
```

Your callback for disconnection will be executed whenever the remote server
closes the connection, or when you close the socket on your end.
```swift
// in class of `object` above
public cb func OnDisconnection() {
    FTLog(s"Connection is closed.");
}
```

When you don't need the socket anymore:
```swift
Socket.Destroy(socket);
```

> [!NOTE]  
> Usually, a `Socket.Create` call should be followed by a `Socket.Destroy` call.
> In any-case, the plugin will try to disconnect and dispose of remaining 
> sockets when the game shuts down.

### Cyber Engine Tweaks

Import API of this plugin:
```lua
local RedSocket = GetMod("RedSocket")

if RedSocket == nil then
    print("RedSocket is not installed.")
    return
end
```

Create a socket:
```lua
local socket = RedSocket.createSocket()
```

Register listener with callbacks:
```lua
---@param command string
local function OnCommand(command)
    print("Command: " .. command)
end

---@param status integer
local function OnConnection(status)
    if status ~= 0 then
        print("Failed to connect to server.")
        -- See in red4ext/logs/ for more details.
        return
    end
    print("Ready to read/write commands.")
end

-- Optional
local function OnDisconnection()
    print("Connection is closed.")
end

-- Optional
local function OnError()
	print("Cannot send command: too many failed attempts.")
end

socket:RegisterListener(OnCommand,
                        OnConnection,
                        OnDisconnection,
                        OnError)
```

Connect to a server:
```lua
socket:Connect("127.0.0.1", 2077)
```

Send a command:
```lua
socket:SendCommand("chat Hello world!")
```

Send a command with error callback:
```lua
socket:SendCommand("<big chunk>", 5, OnError)
```

Disconnect from server:
```lua
socket:Disconnect()
```

> [!TIP]  
> You should close sockets based on your usage. In any case, CET plugin keeps
> track of sockets you created. On shutdown event, it will try to disconnect 
> them.


# Development
Contributions are welcome, feel free to fill an issue or a PR.

## Usage
1. Install requirements:
- XMake
- Visual Studio 2022+
- [red-cli] v0.4.0+
2. Configure project with:
```shell
xmake -y
```

3. Generate Visual Studio solution:
```shell
xmake project -k vsxmake
```

3. Open .sln and build target `RedSocket` in Debug mode.

It will install scripts and plugin in game's directory, thanks to [red-cli].

## Release
1. Open .sln and build target `RedSocket` in Release mode.

It will prepare outputs and create an archive ready to release. 

<!-- Table of links -->
[RED4ext]: https://github.com/WopsS/RED4ext
[Redscript]: https://github.com/jac3km4/redscript
[Cyber Engine Tweaks]: https://github.com/maximegmd/CyberEngineTweaks
[latest archive]: https://github.com/rayshader/cp2077-red-socket/releases/latest
[red-cli]: https://github.com/rayshader/cp2077-red-cli/releases/latest
