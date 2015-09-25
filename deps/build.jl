@windows_only begin
	if Sys.ARCH == :x86_64
		# 64-bit version is not available in an end-user package, so we download the SDK
		srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Windows%20SDK/1.7.8/DevIL-SDK-x64-1.7.8.zip?r=&amp;ts=$(int(time()))&amp;use_mirror=auto_select"
		fileName = "DevIL-SDK-x64-1.7.8.zip"
	elseif Sys.ARCH == :x86
		srcUrl = "http://downloads.sourceforge.net/project/openil/DevIL%20Win32/1.7.8/DevIL-EndUser-x86-1.7.8.zip?r=&amp;ts=$(int(time()))&amp;use_mirror=auto_select"
		fileName = "DevIL-EndUser-x86-1.7.8.zip"
	else
		error("DevIL: Unsupported Windows architecture")
	end
	
	dstDir = Pkg.dir("DevIL", "deps", string(Sys.ARCH))
	if (!isdir(dstDir))
		mkdir(dstDir)
	end
	dstFile = dstDir * "\\" * fileName
	download(srcUrl, dstFile)
	run(`"$JULIA_HOME\\7z.exe" e "$dstFile" *.dll -o"$dstDir" -y`)
	rm(dstFile)
end

using BinDeps
@BinDeps.setup

libnames = ["devil", "libdevil1c2"]
libdevil = library_dependency("devil")

@linux_only begin
    provides(AptGet, "libdevil1c2", libdevil)
    provides(Pacman, "devil", libdevil)
    provides(Yum, "DevIL", libdevil)
end

@osx_only begin
    if Pkg.installed("Homebrew") === nothing
        error("Homebrew package not installed, please run Pkg.add(\"Homebrew\")")
    end
    using Homebrew
    provides(Homebrew.HB, "devil", libdevil, os = :Darwin)
end

@BinDeps.install Dict([(:libdevil, :libdevil)])

