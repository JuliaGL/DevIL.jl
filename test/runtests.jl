using DevIL, TestImages

for image in Pkg.dir("TestImages", "images")
    DevIL.load_(image)
end
