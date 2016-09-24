@static if is_windows()
	ts = Int(floor(time()))
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
	
	dstDir = Pkg.dir("DevIL", "deps", string(Sys.ARCH))
	if (!isdir(dstDir))
		mkdir(dstDir)
	end
	dstFile = dstDir * "\\" * fileName
	download(srcUrl, dstFile)
	run(`"$JULIA_HOME\\7z.exe" e "$dstFile" *.dll -o"$dstDir" -y`)
	rm(dstFile)
end

@static if is_linux()
    run(`sudo apt-get install libdevil1c2`)
end

