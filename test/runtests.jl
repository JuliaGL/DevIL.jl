using DevIL, TestImages, FileIO
using Base.Test

const imagepaths = map(readdir(TestImages.imagedir)) do name
    joinpath(TestImages.imagedir, name)
end

# it'd be nice to confirm that the images have the right orientation and are not
# messed up. But not erroring is already pretty good for now!
imgs = []
@testset "from path" begin
    empty!(imgs)
    for path in imagepaths
        push!(imgs, DevIL.load_(path))
    end
    @test length(imgs) == 18
end
@testset "from io" begin
    empty!(imgs)
    for path in imagepaths
        push!(imgs, open(path) do io
            DevIL.load_(io)
        end)
    end
    @test length(imgs) == 18
end
@testset "from lump" begin
    empty!(imgs)
    for path in imagepaths
        push!(imgs, open(path) do io
            DevIL.load_(read(io))
        end)
    end
    @test length(imgs) == 18
end


@testset "saving" begin
    img = first(imgs)
    for imformat in (format"JPEG", format"PNG")
        tmp = Vector{UInt8}(sizeof(img))
        @testset "to Vector{UInt8}" begin
            DevIL.save_(tmp, img)
            @test true
        end
        mktemp() do f, io
            @testset "to stream" begin
                DevIL.save_(Stream(imformat, io), img)
                @test true
            end
            close(io)
            ext = info(imformat)[2]
            ext = isa(ext, Vector) ? ext[1] : ext
            @testset "to path $imformat" begin
                DevIL.save_(f*ext, img)
                @test true
            end
        end
    end
end
