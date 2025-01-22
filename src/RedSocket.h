#pragma once

#include "RedSocketPCH.h"

#include <atomic>
#include <vector>
#include <deque>

#include <asio.hpp>
#include <RED4ext/Scripting/IScriptable.hpp>
#include <RedLib.hpp>

class RedSocket : public Red::IScriptable {
    struct RedCallback {
        Red::Handle<Red::IScriptable> Object;
        Red::CName OnCommand;
        Red::CName OnDisconnection;
    };
    constexpr static std::size_t kBufferSize = 1024;

    asio::io_context m_context;
    asio::ip::tcp::socket m_socket;

    Red::CString m_ipAddress;
    uint16_t m_port;
    std::atomic_bool m_isConnected;

    std::string m_buffer;

    RedCallback m_callback;

    void ReadCommand();
    Red::CString GetCommand();

public:
    RedSocket();
    ~RedSocket() override;

    bool IsConnected() const;

    void RegisterListener(const Red::Handle<Red::IScriptable>& p_object, const Red::CName& p_onCommandReceived,
                          const Red::Optional<Red::CName>& p_onDisconnected);

    bool Connect(const Red::CString& p_ipAddress, uint16_t p_port);
    void Disconnect();

    void Poll();
    void SendCommand(const Red::CString& p_command);

    RTTI_IMPL_TYPEINFO(RedSocket)
    RTTI_IMPL_ALLOCATOR()
};

RTTI_DEFINE_CLASS(RedSocket, "Socket", {
    RTTI_ALIAS("RedSocket.Socket");

    RTTI_METHOD(IsConnected);

    RTTI_METHOD(RegisterListener);

    RTTI_METHOD(Connect);
    RTTI_METHOD(Disconnect);

    RTTI_METHOD(SendCommand);
})
