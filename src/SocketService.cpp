#include "SocketService.h"

void SocketService::Track(const Red::Handle<RedSocket>& p_socket) {
    if (!p_socket->IsTracked()) {
        return;
    }
    m_mutex.Lock();
    m_sockets.PushBack(p_socket);
    m_mutex.Unlock();
}

void SocketService::Untrack(const Red::Handle<RedSocket>& p_socket) {
    if (!p_socket->IsTracked()) {
        return;
    }
    m_mutex.Lock();
    m_sockets.Remove(p_socket);
    m_mutex.Unlock();
}

void SocketService::Update() {
    m_mutex.LockShared();
    const auto sockets = m_sockets;
    m_mutex.UnlockShared();

    for (auto& socket: sockets) {
        socket->Run();
        socket->Poll();
    }
}

void SocketService::Stop() {
    m_mutex.LockShared();
    const auto sockets = m_sockets;
    m_mutex.UnlockShared();

    for (auto& socket: sockets) {
        socket->Disconnect();
    }
    m_mutex.Lock();
    m_sockets.Clear();
    m_mutex.Unlock();
}
