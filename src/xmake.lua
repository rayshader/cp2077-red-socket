target("RedSocket")
    set_kind("shared")
    set_group("RedSocket")
    set_basename("RedSocket")

    -- Configuration
    add_extrafiles(
        "xmake.lua",
        "../.clang-format",
        "../.gitattributes",
        "../.gitignore",
        "../.gitmodules",
        "../Config.h.in",
        "../LICENSE",
        "../README.md",
        "../red.config.json")

    -- Files
    add_files("**.cpp")
    add_headerfiles("**.h", "**.hpp")
    add_includedirs(".")

    set_configdir("$(builddir)/config")
    add_configfiles("../Config.h.in")
    add_includedirs("$(builddir)/config")

    set_pcxxheader("RedSocketPCH.h")

    -- Dependencies
    add_deps(
        "RED4ext.SDK",
        "RedLib")

    -- Linking
    add_packages("asio")
    add_links("User32")

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