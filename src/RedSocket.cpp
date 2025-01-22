#include "RedSocket.h"

#include <string>

#include "Logger.h"

RedSocket::RedSocket() :
    m_socket(m_context), m_port(0), m_isConnected(false) {
}

RedSocket::~RedSocket() {
    m_context.stop();
}

void RedSocket::RegisterListener(const Red::Handle<Red::IScriptable>& p_object, const Red::CName& p_onCommandReceived,
                                 const Red::Optional<Red::CName>& p_onDisconnected) {
    m_callback = {
            .Object = p_object,
            .OnCommand = p_onCommandReceived,
            .OnDisconnection = p_onDisconnected.value,
    };
}

bool RedSocket::Connect(const Red::CString& p_ipAddress, uint16_t p_port) {
    if (IsConnected()) {
        Logger::Warn("A connection is already established.");
        return false;
    }
    if (!m_callback.Object || m_callback.OnCommand.IsNone()) {
        Logger::Warn("You must call RegisterListener before connecting.");
        return false;
    }
    try {
        asio::ip::tcp::resolver resolver(m_context);
        const auto endpoints = resolver.resolve(p_ipAddress.c_str(), std::to_string(p_port));

        asio::connect(m_socket, endpoints);
        m_socket.non_blocking(true);

        m_ipAddress = p_ipAddress;
        m_port = p_port;
        m_isConnected = true;
        Logger::Info("Connected on {}:{}", p_ipAddress.c_str(), p_port);

        Red::JobQueue queue;

        queue.Dispatch([this] {
            Logger::Info("Listening for commands...");
            while (m_isConnected) {
                Poll();
                std::this_thread::sleep_for(std::chrono::milliseconds(16));
            }
            Logger::Info("Stop listening");
            if (!m_callback.OnDisconnection.IsNone()) {
                Red::CallVirtual(m_callback.Object, m_callback.OnDisconnection);
            }
        });
        return true;
    } catch (const std::exception& e) {
        Logger::Error("Failed to connect: {}", e.what());
        return false;
    }
}

void RedSocket::Disconnect() {
    m_isConnected = false;
    try {
        m_socket.close();
        Logger::Info("Disconnected from {}:{}", m_ipAddress.c_str(), m_port);
    } catch (const std::exception& e) {
        Logger::Error("Failed to disconnect: {}", e.what());
    }
}

void RedSocket::Poll() {
    ReadCommand();
    const auto command = GetCommand();

    if (command.length == 0) {
        return;
    }
    // TODO: handle busy/ready reserved commands.
    //       required when game is stopped during debugging (breakpoint).
    //       allows to pause/restore socket without user interaction.
    Red::CallVirtual(m_callback.Object, m_callback.OnCommand, command);
}

void RedSocket::SendCommand(const Red::CString& p_command) {
    std::string message(p_command.c_str());

    if (message.find_first_of("\r\n") != std::string::npos) {
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
    static char buffer[kBufferSize];

    std::fill_n(buffer, kBufferSize, '\0');
    try {
        const auto length = m_socket.read_some(asio::buffer(buffer, kBufferSize));

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

bool RedSocket::IsConnected() const {
    return m_isConnected;
}
