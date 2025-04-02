module RedSocket

public native class Socket {
    public static native func Create() -> ref<Socket>;
    public static native func Destroy(socket: ref<Socket>);

    public native func IsConnected() -> Bool;

    public native func RegisterListener(object: ref<IScriptable>,
                                        onCommand: CName,
                                        onConnection: CName,
                                        opt onDisconnection: CName);
    public native func UnregisterListener();

    public native func Connect(ipAddress: String, port: Uint16);
    public native func Disconnect();

    public native func SendCommand(command: String);
}