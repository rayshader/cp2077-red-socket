#include "Config.h"
#include "Logger.h"
#include "SocketService.h"

namespace {
bool OnUpdate(Red::CGameApplication* p_app) {
    SocketService::Get().Update();
    return false;
}

bool OnStop(Red::CGameApplication* p_app) {
    SocketService::Get().Stop();
    return true;
}
}  // namespace

RED4EXT_C_EXPORT bool RED4EXT_CALL Main(RED4ext::v1::PluginHandle p_handle, RED4ext::v1::EMainReason p_reason,
                                        const RED4ext::v1::Sdk* p_sdk) {
    switch (p_reason) {
        case RED4ext::v1::EMainReason::Load: {
            Logger::Load(p_handle, p_sdk);

            RED4ext::v1::GameState state;
            state.OnEnter = nullptr;
            state.OnUpdate = &OnUpdate;
            state.OnExit = &OnStop;
            p_sdk->gameStates->Add(p_handle, Red::EGameStateType::Running, &state);

            Red::TypeInfoRegistrar::RegisterDiscovered();
            break;
        }
        case RED4ext::v1::EMainReason::Unload: {
            break;
        }
    }
    return true;
}

RED4EXT_C_EXPORT void RED4EXT_CALL Query(RED4ext::v1::PluginInfo* p_info) {
    p_info->name = L"RedSocket";
    p_info->author = L"Rayshader";
    p_info->version = RED4EXT_V1_SEMVER(REDSOCKET_MAJOR, REDSOCKET_MINOR, REDSOCKET_PATCH);
    p_info->runtime = RED4EXT_V1_RUNTIME_VERSION_LATEST;
    p_info->sdk = RED4EXT_V1_SDK_VERSION_1_0_0_COMPAT_0_5_0;
}

RED4EXT_C_EXPORT uint32_t RED4EXT_CALL Supports() {
    return RED4EXT_API_VERSION_1_COMPAT_0;
}