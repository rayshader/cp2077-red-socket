#include "RedSocket.h"

#include <string>

#include "Logger.h"

RedSocket::RedSocket(bool p_isTracked) :
    m_isTracked(p_isTracked), m_socket(m_context), m_port(0), m_isConnected(false) {
}

RedSocket::~RedSocket() {
    m_context.stop();
}

Red::Handle<RedSocket> RedSocket::Create() {
    const auto socket = Red::MakeHandle<RedSocket>(true);

    SocketService::Get().Track(socket);
    return socket;
}

void RedSocket::Destroy(const Red::Handle<RedSocket>& p_socket) {
    SocketService::Get().Untrack(p_socket);
}

bool RedSocket::IsTracked() const {
    return m_isTracked;
}

bool RedSocket::IsConnected() const {
    return m_isConnected;
}

bool RedSocket::HasListener() const {
    return m_callback.Object && !m_callback.OnCommand.IsNone() && !m_callback.OnConnection.IsNone();
}

void RedSocket::RegisterListener(const Red::Handle<Red::IScriptable>& p_object, const Red::CName& p_onCommand,
                                 const Red::CName& p_onConnection,
                                 const Red::Optional<Red::CName>& p_onDisconnection) {
    if (!IsTracked()) {
        return;
    }
    if (IsConnected()) {
        Logger::Warn("You cannot change listener while connected.");
        return;
    }
    m_callback.Object = p_object;
    m_callback.OnCommand = p_onCommand;
    m_callback.OnConnection = p_onConnection;
    m_callback.OnDisconnection = p_onDisconnection.value;
}

void RedSocket::UnregisterListener() {
    if (!IsTracked()) {
        return;
    }
    if (IsConnected()) {
        Logger::Warn("You cannot remove listener while connected.");
        return;
    }
    m_callback.Object = nullptr;
    m_callback.OnCommand = nullptr;
    m_callback.OnConnection = nullptr;
    m_callback.OnDisconnection = nullptr;
}

void RedSocket::Connect(const Red::CString& p_ipAddress, uint16_t p_port) {
    if (!IsTracked()) {
        return;
    }
    if (IsConnected()) {
        Logger::Warn("A connection is already established.");
        return;
    }
    if (!HasListener()) {
        Logger::Warn("You must register a listener before connecting.");
        return;
    }
    try {
        asio::ip::tcp::resolver resolver(m_context);
        const auto endpoints = resolver.resolve(p_ipAddress.c_str(), std::to_string(p_port));

        asio::async_connect(m_socket, endpoints,
                            [this](const asio::error_code& p_error, const asio::ip::tcp::endpoint& p_endpoint) {
                                if (p_error) {
                                    Logger::Error("Failed to connect: {}", p_error.message());
                                    Red::CallVirtual(m_callback.Object, m_callback.OnConnection, p_error.value());
                                    return;
                                }
                                m_ipAddress = p_endpoint.address().to_string();
                                m_port = p_endpoint.port();
                                m_socket.non_blocking(true);
                                m_isConnected = true;
                                Logger::Info("Connected on {}:{}", m_ipAddress.c_str(), m_port);
                                Red::CallVirtual(m_callback.Object, m_callback.OnConnection, 0);
                            });
    } catch (const std::exception& e) {
        Logger::Error("Failed to connect: {}", e.what());
    }
}

void RedSocket::Disconnect() {
    if (!IsTracked()) {
        return;
    }
    try {
        m_socket.close();
    } catch (const std::exception& e) {
        Logger::Error("Unexpected failure while disconnecting: {}", e.what());
    }
    m_isConnected = false;
    if (!m_callback.OnDisconnection.IsNone()) {
        Red::CallVirtual(m_callback.Object, m_callback.OnDisconnection);
    }
    Logger::Info("Disconnected from {}:{}", m_ipAddress.c_str(), m_port);
    m_ipAddress = "";
    m_port = 0;
}

void RedSocket::Run() {
    try {
        m_context.poll();
    } catch (const asio::error_code& error) {
        Logger::Error("Failed to poll: {}", error.message());
    }
}

void RedSocket::Poll() {
    if (!m_isConnected) {
        return;
    }
    ReadCommand();
    const auto command = GetCommand();

    if (command.length == 0) {
        return;
    }
    Red::JobQueue queue;

    queue.Dispatch([this, command] {
        Red::CallVirtual(m_callback.Object, m_callback.OnCommand, command);
    });
}

void RedSocket::SendCommand(const Red::CString& p_command) {
    if (!IsTracked()) {
        return;
    }
    if (!IsConnected()) {
        return;
    }
    std::string message(p_command.c_str());

    if (message.find("\r\n") != std::string::npos) {
        return;
    }
    message += "\r\n";
    Red::JobQueue queue;

    queue.Dispatch([this, message] {
        try {
            asio::write(m_socket, asio::buffer(message));
        } catch (const std::exception& e) {
            Logger::Error("Failed to send command: {}", e.what());
        }
    });
}

void RedSocket::ReadCommand() {
    static char buffer[BUFFER_SIZE];

    std::fill_n(buffer, BUFFER_SIZE, '\0');
    try {
        const auto length = m_socket.read_some(asio::buffer(buffer, BUFFER_SIZE));

        if (length == 0) {
            return;
        }
        m_buffer += buffer;
    } catch (const asio::system_error& e) {
        if (e.code() == asio::error::eof) {
            Disconnect();
            return;
        }
        if (e.code() == asio::error::would_block || e.code() == asio::error::try_again) {
            return;
        }
        Logger::Error("Failed to read on socket: {}", e.what());
    }
}

Red::CString RedSocket::GetCommand() {
    if (!IsConnected()) {
        return {};
    }
    const auto eoc = m_buffer.find("\r\n");

    if (eoc == std::string::npos) {
        return {};
    }
    const Red::CString command = m_buffer.substr(0, eoc);

    if (m_buffer.length() > eoc + 2) {
        m_buffer = m_buffer.substr(eoc + 2);
    } else {
        m_buffer.clear();
    }
    return command;
}
