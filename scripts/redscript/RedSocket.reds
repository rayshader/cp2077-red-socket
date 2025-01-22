module RedSocket

public native class Socket {
    public native func IsConnected() -> Bool;

    public native func RegisterListener(object: ref<IScriptable>, onCommand: CName, opt onConnection: CName);

    public native func Connect(ipAddress: String, port: Uint16) -> Bool;
    public native func Disconnect();

    public native func SendCommand(command: String);
}