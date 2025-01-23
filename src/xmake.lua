target("RedSocket")
    set_kind("shared")
    set_group("RedSocket")

    set_basename("RedSocket")

    -- Files
    add_files("**.cpp")
    add_headerfiles("**.h", "**.hpp")

    set_pcxxheader("RedSocketPCH.h")
    add_includedirs(".")

    -- Configuration

    -- Dependencies
    add_deps(
        "RED4ext.SDK",
        "RedLib")

    -- Linking
    add_packages("asio")
    add_links("User32")

    -- Generate version header
    on_load(function (target)
        local version = get_config("version")
        local major, minor, patch = version:match("(%d+)%.(%d+)%.(%d+)")
        local header = path.join(os.projectdir(), "src", "Version.h")

        io.writefile(header, string.format([[
// This file was generated with XMake, do not edit manually.

#pragma once

#define REDSOCKET_MAJOR %s
#define REDSOCKET_MINOR %s
#define REDSOCKET_PATCH %s

#define REDSOCKET_VERSION "%s"]], major, minor, patch, version))
        end)

    -- Install scripts and library in game's directory
    after_build(function()
        local stdout, _ = os.iorunv("red-cli", {"--help"})

        if string.find(stdout, "red%-cli") == nil then
            print("Could not find red-cli.")
            print("See https://github.com/rayshader/cp2077-red-cli")
            return
        end

        if is_mode("debug") then
            stdout, _ = os.iorunv("red-cli", {"install"})
            if string.find(stdout, "Installation of \27%[1mRedSocket\27%[22m done") == nil then
                print("Failed to install RedSocket in game's directory.")
                return
            end
            print("RedSocket is installed in game's directory.")
        elseif is_mode("release") then
            local version = get_config("version"):gsub("%-", "%%%-")

            stdout, _ = os.iorunv("red-cli", {"pack"})
            if string.find(stdout, "Archive \27%[1mRedSocket%-" .. version .. ".zip\27%[22m ready") == nil then
                print("Failed to create archive for RedSocket.")
                return
            end
            print("RedSocket is ready for release.")
        end
    end)
target_end()