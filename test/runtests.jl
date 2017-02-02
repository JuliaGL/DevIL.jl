using DevIL, TestImages

images = readdir(Pkg.dir("TestImages", "images"))
filter!(images) do img
    !(
        endswith(img, ".tif") ||
        endswith(img, ".tiff")
    )
end
for image in images
    DevIL.load_(Pkg.dir("TestImages", "images", image))
end
