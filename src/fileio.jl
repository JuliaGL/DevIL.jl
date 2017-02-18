using FileIO: DataFormat, @format_str, Stream, File, filename, stream


const image_formats = Dict(
    format"BMP" => IL_BMP,
    format"DCX" => IL_DCX,
    format"GIF" => IL_GIF,
    format"HDR" => IL_HDR,
    format"ICO" => IL_ICO,
    format"JP2" => IL_JP2,
    format"JPEG" => IL_JPG,
    format"PCX" => IL_PCX,
    format"PGM" => IL_PNM,
    format"PNG" => IL_PNG,
    format"PSD" => IL_PSD,
    format"RGB" => IL_RGB,
    format"TIFF" => IL_TIF,
    format"TGA" => IL_TGA
)

load{T <: DataFormat}(imagefile::File{T}, args...; key_args...) = load_(filename(imagefile), args...; key_args...)
load(filename::AbstractString, args...; key_args...) = load_(filename, args...; key_args...)
save{T <: DataFormat}(imagefile::File{T}, args...; key_args...) = save_(filename(imagefile), args...; key_args...)
save(filename::AbstractString, args...; key_args...) = save_(filename, args...; key_args...)

load{T <: DataFormat}(imgstream::Stream{T}, args...; key_args...) = load_(stream(imgstream), args...; key_args...)
load(imgstream::IO, args...; key_args...) = load_(imgstream, args...; key_args...)
save{T <: DataFormat}(imgstream::Stream{T}, args...; key_args...) = save_(imgstream, args...; key_args...)

function assert_devil(err, msg = "")
    if !Bool(err)
        println(STDERR, "DevIL Error: ", msg)
        error(string(ilGetError()))
    end
end

function newimg()
    img = ilGenImage()
    ilBindImage(img)
    img
end

function to_string(str)
    String(str)
end

function load_(file::AbstractString; ImageType = Array)
    img = newimg()
    err = ilLoadImage(to_string(file))
    assert_devil(err, "while loading $file")
    data = getimage()
    ilDeleteImage(img)
    data
end
function load_(stream::IO; ImageType = Array)
    img = newimg()
    err = ilLoadF(IL_TYPE_UNKNOWN, Libc.FILE(stream).ptr)
    assert_devil(err, "while loading stream")
    data = getimage()
    ilDeleteImage(img)
    data
end
function load_(lump::Vector{UInt8}; ImageType = Array)
    img = newimg()
    err = ilLoadL(IL_TYPE_UNKNOWN, lump, sizeof(lump))
    assert_devil(err, "while loading image from Vector{UInt8}")
    data = getimage()
    ilDeleteImage(img)
    data
end

const colordict = Dict(
    IL_COLOR_INDEX => Void,
    IL_ALPHA => Void,
    IL_RGB => RGB,
    IL_RGBA => RGBA,
    IL_BGR => BGR,
    IL_BGRA => BGRA,
    IL_LUMINANCE => Gray,
    IL_LUMINANCE_ALPHA => GrayA
)
devilcolor{T<:RGB}(::Type{T}) = IL_RGB
devilcolor{T<:RGBA}(::Type{T}) = IL_RGBA
devilcolor{T<:BGRA}(::Type{T}) = IL_BGRA
devilcolor{T<:BGR}(::Type{T}) = IL_BGR
devilcolor{T<:Gray}(::Type{T}) = IL_LUMINANCE
devilcolor{T<:GrayA}(::Type{T}) = IL_LUMINANCE_ALPHA
const devil_colordict = Dict(zip(values(colordict), keys(colordict)))
const pixeltypedict = Dict(
    IL_BYTE           => Int8,
    IL_UNSIGNED_BYTE  => N0f8,
    IL_SHORT          => Int16,
    IL_UNSIGNED_SHORT => N0f16,
    IL_INT            => Int32,
    IL_UNSIGNED_INT   => N0f32,
    IL_HALF           => Float16,
    IL_FLOAT          => Float32,
    IL_DOUBLE         => Float64,
)
const devil_pixeltypedict = Dict(zip(values(pixeltypedict), keys(pixeltypedict)))

function colortype()
    colorformat = ilGetInteger(IL_FORMAT_MODE)
    color = get(colordict, colorformat) do
        error("Not a known colortype: $colorformat")
    end
    if color == Void
        error("Colortype is indexed, which is not supported right now")
    end
    pixformat = ilGetInteger(IL_TYPE_MODE)
    PX = get(pixeltypedict, pixformat) do
        error("Not a known pixeltype: $pixformat")
    end
    color{PX}, colorformat, pixformat
end

function getimage()
    ilEnable(IL_ORIGIN_SET)
    ilOriginFunc(IL_ORIGIN_LOWER_LEFT)
    w = Int(ilGetInteger(IL_IMAGE_WIDTH))
    h = Int(ilGetInteger(IL_IMAGE_HEIGHT))
    frames = Int(ilGetInteger(IL_NUM_IMAGES))
    ctype, dcolor, dpix = colortype()
    size = frames == 0 ? (w, h) : (w, h, frames)
    image = Array(ctype, size)
    # TODO return axis array for spatial order, xy?!
    ilCopyPixels(0, 0, 0, w, h, 1, dcolor, dpix, image)
    #transform(image)
    rotl90(image)
end

function devilcolor(img)
    CT = eltype(img)
    CET = eltype(CT)
    px = get(devil_pixeltypedict, CET) do
        error("Not a supported pixel type: $CET")
    end
    if CT <: Number
        return IL_LUMINANCE, px
    end
    return devilcolor(CT), px, length(CT)
end

typealias Color1{T}            Color{T,1}
typealias Color2{T,C<:Color1}  TransparentColor{C,T,2}
typealias Color3{T}            Color{T,3}
typealias Color4{T,C<:Color3}  TransparentColor{C,T,4}

# ImageMagick element-mapping function. Converts to RGB/RGBA and uses
# N0f8 "inner" element type.
mapIM(c::Color1) = mapIM(convert(Gray, c))
mapIM{T}(c::Gray{T}) = convert(Gray{N0f8}, c)
mapIM{T<:Normed}(c::Gray{T}) = c

mapIM(c::Color2) = mapIM(convert(GrayA, c))
mapIM{T}(c::GrayA{T}) = convert(GrayA{N0f8}, c)
mapIM{T<:Normed}(c::GrayA{T}) = c

mapIM(c::Color3) = mapIM(convert(RGB, c))
mapIM{T}(c::RGB{T}) = convert(RGB{N0f8}, c)
mapIM{T<:Normed}(c::RGB{T}) = c

mapIM(c::Color4) = mapIM(convert(RGBA, c))
mapIM{T}(c::RGBA{T}) = convert(RGBA{N0f8}, c)
mapIM{T<:Normed}(c::RGBA{T}) = c

mapIM(x::UInt8) = reinterpret(N0f8, x)
mapIM(x::Bool) = convert(N0f8, x)
mapIM(x::AbstractFloat) = convert(N0f8, x)
mapIM(x::Normed) = x

# Make the data contiguous in memory, this is necessary for
# imagemagick since it doesn't handle stride.
to_contiguous(A::Array) = A
to_contiguous(A::AbstractArray) = copy(A)
to_contiguous(A::SubArray) = copy(A)
to_contiguous(A::BitArray) = convert(Array{N0f8}, A)
#to_contiguous(A::ColorView) = to_contiguous(channelview(A))

to_explicit{C<:Colorant}(A::Array{C}) = to_explicit(channelview(A))
#to_explicit{T}(A::ChannelView{T}) = to_explicit(copy!(Array{T}(size(A)), A))
to_explicit{T<:Normed}(A::Array{T}) = rawview(A)
to_explicit{T<:AbstractFloat}(A::Array{T}) = to_explicit(convert(Array{N0f8}, A))


function bind_image(img)
    if ndims(img) > 3
        error("At most 3 dimensions are supported")
    end
    ctype, pixtype, bpx = devilcolor(img)
    ilTexImage(
        size(img, 2), size(img, 1),
        ndims(img) == 3 ? size(img, 3) : 1,
        bpx, ctype, pixtype,
        rotr90(img)
    )
end


function save_(file::AbstractString, image)
    img = newimg()
    bind_image(image)
    err = ilSaveImage(to_string(file))
    ilDeleteImage(img)
    assert_devil(err, "while saving $file")
end

function save_{T}(io::Stream{T}, image)
    img = newimg()
    bind_image(image)
    err = ilSaveF(
        get(image_formats, T, IL_TYPE_UNKNOWN),
        Libc.FILE(stream(io)).ptr
    )
    ilDeleteImage(img)
    #assert_devil(err, "while saving to stream")
end

function save_(lump::Vector{UInt8}, image)
    img = newimg()
    bind_image(image)
    err = ilSaveL(IL_JPG, lump, sizeof(lump))
    ilDeleteImage(img)
    #assert_devil(err, "while saving to Vector{UInt8}")
end
