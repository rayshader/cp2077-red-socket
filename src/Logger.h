#pragma once

#include "RedSocketPCH.h"

#include <format>

#include <RED4ext/RED4ext.hpp>

class Logger {
    RED4ext::PluginHandle m_handle = nullptr;
    const RED4ext::Logger* m_logger = nullptr;

public:
    Logger() = default;

    Logger(RED4ext::PluginHandle p_handle, const RED4ext::Sdk* p_sdk) {
        m_handle = p_handle;
        m_logger = p_sdk->logger;
    }

    Logger& operator=(const Logger& p_other) {
        if (this == &p_other) {
            return *this;
        }
        m_handle = p_other.m_handle;
        m_logger = p_other.m_logger;
        return *this;
    }

    static Logger& Get() {
        static Logger logger;

        return logger;
    }

    static void Load(RED4ext::PluginHandle p_handle, const RED4ext::Sdk* p_sdk) {
        Get() = Logger(p_handle, p_sdk);
    }

    static void Trace(const char* p_message) {
        Get()._Trace(p_message);
    }

    template<class... Args>
    static void Trace(const std::format_string<Args...>& p_fmt, Args&&... p_args) {
        const auto message = std::format(p_fmt, std::forward<Args>(p_args)...);

        Get()._Trace(message.c_str());
    }

    static void Debug(const char* p_message) {
        Get()._Debug(p_message);
    }

    template<class... Args>
    static void Debug(const std::format_string<Args...>& p_fmt, Args&&... p_args) {
        const auto message = std::format(p_fmt, std::forward<Args>(p_args)...);

        Get()._Debug(message.c_str());
    }

    static void Info(const char* p_message) {
        Get()._Info(p_message);
    }

    template<class... Args>
    static void Info(const std::format_string<Args...>& p_fmt, Args&&... p_args) {
        const auto message = std::format(p_fmt, std::forward<Args>(p_args)...);

        Get()._Info(message.c_str());
    }

    static void Warn(const char* p_message) {
        Get()._Warn(p_message);
    }

    template<class... Args>
    static void Warn(const std::format_string<Args...>& p_fmt, Args&&... p_args) {
        const auto message = std::format(p_fmt, std::forward<Args>(p_args)...);

        Get()._Warn(message.c_str());
    }

    static void Error(const char* p_message) {
        Get()._Error(p_message);
    }

    template<class... Args>
    static void Error(const std::format_string<Args...>& p_fmt, Args&&... p_args) {
        const auto message = std::format(p_fmt, std::forward<Args>(p_args)...);

        Get()._Error(message.c_str());
    }

    static void Critical(const char* p_message) {
        Get()._Critical(p_message);
    }

    template<class... Args>
    static void Critical(const std::format_string<Args...>& p_fmt, Args&&... p_args) {
        const auto message = std::format(p_fmt, std::forward<Args>(p_args)...);

        Get()._Critical(message.c_str());
    }

    void _Trace(const char* p_message) const {
        m_logger->Trace(m_handle, p_message);
    }

    void _Debug(const char* p_message) const {
        m_logger->Debug(m_handle, p_message);
    }

    void _Info(const char* p_message) const {
        m_logger->Info(m_handle, p_message);
    }

    void _Warn(const char* p_message) const {
        m_logger->Warn(m_handle, p_message);
    }

    void _Error(const char* p_message) const {
        m_logger->Error(m_handle, p_message);
    }

    void _Critical(const char* p_message) const {
        m_logger->Critical(m_handle, p_message);
    }
};