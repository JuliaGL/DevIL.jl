using Compat
@windows_only using ZipFile
@windows_only begin
	t = round(Int, time())
	if WORD_SIZE == 64
		# 64-bit version is not available in an end-user package, so we download the SDK
		srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Windows%20SDK/1.7.8/DevIL-SDK-x64-1.7.8.zip?r=&amp;ts=$(t)&amp;use_mirror=auto_select"
	elseif WORD_SIZE == 32
		srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Win32/1.7.8/DevIL-EndUser-x86-1.7.8.zip?r=&amp;ts=$(t)&amp;use_mirror=auto_select"
	else
		error("DevIL: Unsupported Windows architecture: $(Sys.ARCH)")
	end
	zipped_lib = download(srcUrl)
	library_dir = Pkg.dir("DevIL", "deps", "bin")
	isdir(library_dir) || mkdir(library_dir)
	zr = ZipFile.Reader(zipped_lib)
	lib_name = ""
	for file in zr.files #uncompress
		filename = basename(file.name)
		if splitext(filename)[2] == ".dll"
			contains(lowercase(filename), "devil") && (lib_name = filename)
			open(joinpath(library_dir, filename), "w") do io
				write(io, readall(file))
			end
		end
	end
    library_name  = joinpath(library_dir, lib_name)
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

