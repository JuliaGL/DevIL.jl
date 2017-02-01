using Compat

if is_windows()
    ts = floor(Int, time())
    if Sys.ARCH == :x86_64
        # 64-bit version is not available in an end-user package, so we download the SDK
        srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Windows%20SDK/1.7.8/DevIL-SDK-x64-1.7.8.zip?r=&amp;ts=$ts&amp;use_mirror=auto_select"
        fileName = "DevIL-SDK-x64-1.7.8.zip"
    elseif Sys.ARCH == :x86
        srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Win32/1.7.8/DevIL-EndUser-x86-1.7.8.zip?r=&amp;ts=$ts&amp;use_mirror=auto_select"
        fileName = "DevIL-EndUser-x86-1.7.8.zip"
    else
        error("DevIL: Unsupported Windows architecture")
    end
    dstDir = joinpath(dirname(@__FILE__), string(Sys.ARCH))
    isdir(dstDir) || mkdir(dstDir)
    dstFile = dstDir * "\\" * fileName
    download(srcUrl, dstFile)
    run(`"$JULIA_HOME\\7z.exe" e "$dstFile" *.dll -o"$dstDir" -y`)
    rm(dstFile)
    library_name = joinpath(dstDir, "DevIL.dll")
    open("deps.jl", "w") do io
        println(io, "const libdevil = \"$(escape_string(library_name))\"")
    end
end

@static if is_unix()
    using BinDeps
    @BinDeps.setup
    libnames = ["devil", "libdevil1c2", "libdevil-dev"]
    libdevil = library_dependency("devil")
end

@static if is_linux()
    provides(AptGet, "libdevil1c2", libdevil)
    provides(Pacman, "libdevil-dev", libdevil)
    provides(Yum, "DevIL", libdevil)
end

@static if is_apple()
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "devil", libdevil, os = :Darwin)
end

@static if is_unix()
    @BinDeps.install Dict([(:libdevil, :libdevil)])
end
