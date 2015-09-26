using Compat
@windows_only begin
	t = round(Int, time())
	if WORD_SIZE == 64
		OS_ARCH = "x64"
		# 64-bit version is not available in an end-user package, so we download the SDK
		srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Windows%20SDK/1.7.8/DevIL-SDK-x64-1.7.8.zip?r=&amp;ts=$(t)&amp;use_mirror=auto_select"
		fileName = "DevIL-SDK-x64-1.7.8.zip"
	elseif WORD_SIZE == 32
		OS_ARCH = "x86"
		srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Win32/1.7.8/DevIL-EndUser-x86-1.7.8.zip?r=&amp;ts=$(t)&amp;use_mirror=auto_select"
		fileName = "DevIL-EndUser-x86-1.7.8.zip"
	else
		error("DevIL: Unsupported Windows architecture: $(Sys.ARCH)")
	end
	dstDir = Pkg.dir("DevIL", "deps", OS_ARCH)
	isdir(dstDir) || mkdir(dstDir)
	dstFile = joinpath(dstDir, fileName)
	zipped_lib = download(srcUrl, dstFile)
	library_dir = Pkg.dir("DevIL", "deps", "bin")
	isdir(library_dir) || mkdir(library_dir)
	run(`"$JULIA_HOME\\7z.exe" e "$zipped_lib" *.dll -o"$library_dir" -y`)
    library_name  = joinpath(library_dir, "DevIL.dll")
	open("deps.jl", "w") do io
		println(io, "const libdevil = \"$(escape_string(library_name))\"")
	end
end


@unix_only using BinDeps
@unix_only @BinDeps.setup
@unix_only begin
libnames = ["devil", "libdevil1c2", "libdevil-dev"]
libdevil = library_dependency("devil")
end

@linux_only begin
    provides(AptGet, "libdevil1c2", libdevil)
    provides(Pacman, "libdevil-dev", libdevil)
    provides(Yum, "DevIL", libdevil)
end

@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "devil", libdevil, os = :Darwin)
end

@unix_only @BinDeps.install Dict([(:libdevil, :libdevil)])

