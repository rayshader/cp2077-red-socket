-- Build configurations
add_rules("mode.debug", "mode.release")

set_policy("build.ccache", true)
set_policy("package.requires_lock", true)

set_config("version", "0.2.0")

-- Languages
set_languages("c99", "cxx20")

-- Dependencies
add_requires(
    "asio")

-- Compilation
set_warnings("all")

if is_plat("windows") then
    add_defines("NOMINMAX", "REDSOCKET_WINDOWS")
end

if is_mode("debug") then
    add_defines("REDSOCKET_DEBUG")
elseif is_mode("release") then
    add_defines("REDSOCKET_RELEASE")
end

includes("src")
includes("vendors")
