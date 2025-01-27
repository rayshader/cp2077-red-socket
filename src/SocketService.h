#pragma once

#include "RedSocketPCH.h"

#include <RED4ext/RED4ext.hpp>
#include <RedLib.hpp>

#include "RedSocket.h"

class SocketService {
    Red::DynArray<Red::Handle<RedSocket>> m_sockets;
    Red::SharedSpinLock m_mutex;

public:
    static SocketService& Get() {
        static SocketService instance;

        return instance;
    }

    void Track(const Red::Handle<RedSocket>& p_socket);
    void Untrack(const Red::Handle<RedSocket>& p_socket);

    void Update();
    void Stop();
};
