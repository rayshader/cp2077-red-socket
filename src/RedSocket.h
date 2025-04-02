#pragma once

#include "RedSocketPCH.h"

#include <atomic>
#include <string>

#include <asio.hpp>
#include <RED4ext/Scripting/IScriptable.hpp>
#include <RedLib.hpp>

#define BUFFER_SIZE 4096

class RedSocket : public Red::IScriptable {
    struct RedCallback {
        Red::Handle<Red::IScriptable> Object;
        Red::CName OnCommand;
        Red::CName OnConnection;
        Red::CName OnDisconnection;
    };

    const bool m_isTracked;

    asio::io_context m_context;
    asio::ip::tcp::socket m_socket;

    Red::CString m_ipAddress;
    uint16_t m_port;
    std::atomic_bool m_isConnected;
    RedCallback m_callback;

    std::string m_buffer;

    void ReadCommand();
    Red::CString GetCommand();

public:
    explicit RedSocket(bool p_isTracked = false);
    ~RedSocket() override;

    static Red::Handle<RedSocket> Create();
    static void Destroy(const Red::Handle<RedSocket>& p_socket);

    bool IsTracked() const;
    bool IsConnected() const;
    bool HasListener() const;

    void RegisterListener(const Red::Handle<Red::IScriptable>& p_object, const Red::CName& p_onCommand,
                          const Red::CName& p_onConnection,
                          const Red::Optional<Red::CName>& p_onDisconnection);
    void UnregisterListener();

    void Connect(const Red::CString& p_ipAddress, uint16_t p_port);
    void Disconnect();

    void Run();
    void Poll();
    void SendCommand(const Red::CString& p_command,
                     const Red::Optional<int32_t, 10>& p_limit,
                     const Red::Optional<Red::Handle<Red::IScriptable>>& p_target,
                     const Red::Optional<Red::CName>& p_error);

    RTTI_IMPL_TYPEINFO(RedSocket)
    RTTI_IMPL_ALLOCATOR()
};

RTTI_DEFINE_CLASS(RedSocket, "Socket", {
    RTTI_ALIAS("RedSocket.Socket");

    RTTI_METHOD(Create);
    RTTI_METHOD(Destroy);

    RTTI_METHOD(IsConnected);

    RTTI_METHOD(RegisterListener);
    RTTI_METHOD(UnregisterListener);

    RTTI_METHOD(Connect);
    RTTI_METHOD(Disconnect);

    RTTI_METHOD(SendCommand);
})
