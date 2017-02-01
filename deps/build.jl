using BinDeps
@BinDeps.setup
libnames = ["devil", "libdevil1c2", "libdevil-dev"]
libdevil = library_dependency("devil", aliases = libnames)

# get library through Homebrew, if available
@static if is_apple()
    if Pkg.installed("Homebrew") == nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "devil", libdevil, os = :Darwin)
end

# download a pre-compiled binary (built by GLFW)
@static if is_windows()
    ts = floor(Int, time())
    url = if Sys.ARCH == :x86_64
        # 64-bit version is not available in an end-user package, so we download the SDK
        "http://downloads.sourceforge.net/project/openil/DevIL%20Windows%20SDK/1.7.8/DevIL-SDK-x64-1.7.8.zip?r=&amp;ts=$ts&amp;use_mirror=auto_select"
    elseif Sys.ARCH == :x86
        "http://downloads.sourceforge.net/project/openil/DevIL%20Win32/1.7.8/DevIL-EndUser-x86-1.7.8.zip?r=&amp;ts=$ts&amp;use_mirror=auto_select"
    else
        error("DevIL: Unsupported Windows architecture: $(Sys.ARCH)")
    end
    archive = string(Sys.ARCH)
	libpath = joinpath(archive, "lib")
	uri = URI(url)
	provides(Binaries, uri, libdevil, unpacked_dir = archive, installed_libpath = libpath, os = :Windows)
end

@static if is_linux()
    provides(AptGet, "libdevil1c2", libdevil)
    provides(Pacman, "libdevil-dev", libdevil)
    provides(Yum, "DevIL", libdevil)
end

@BinDeps.install Dict("devil" => "libdevil")
