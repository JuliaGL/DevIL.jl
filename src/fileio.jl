using FileIO: DataFormat, @format_str, Stream, File, filename, stream

image_formats = [
    format"BMP",
    format"CRW",
    format"CUR",
    format"DCX",
    format"GIF",
    format"HDR",
    format"ICO",
    format"JP2",
    format"JPEG",
    format"PCX",
    format"PGM",
    format"PNG",
    format"PSD",
    format"RGB",
    format"TIFF",
    format"TGA"
]

load{T <: DataFormat}(imagefile::File{T}, args...; key_args...) = load_(filename(imagefile), args...; key_args...)
load(filename::AbstractString, args...; key_args...) = load_(filename, args...; key_args...)
save{T <: DataFormat}(imagefile::File{T}, args...; key_args...) = save_(filename(imagefile), args...; key_args...)
save(filename::AbstractString, args...; key_args...) = save_(filename, args...; key_args...)

load{T <: DataFormat}(imgstream::Stream{T}, args...; key_args...) = load_(stream(imgstream), args...; key_args...)
load(imgstream::IO, args...; key_args...) = load_(imgstream, args...; key_args...)
save{T <: DataFormat}(imgstream::Stream{T}, args...; key_args...) = save_(imgstream, args...; key_args...)

function throw_devil()
    error(iluErrorString(ilGetError()))
end

function load_(file::AbstractString; ImageType = Array)
    img = ilGenImage()
    ilBindImage(img)
    err = Bool(ilLoadImage(String(file)))
    if !err
        println(STDERR, "Error while loading file $file with DevIL")
        throw_devil()
    end
    data = getimage()
    ilDeleteImage(img)
    data
end
function load_(stream::IO; ImageType = Array)
    img = ilGenImage()
    ilBindImage(img)
    ilLoadF(IL_TYPE_UNKNOWN, Libc.FILE(stream).ptr)
    data = getimage()
    ilDeleteImage(img)
    data
end
function load_(lump::Vector{UInt8}; ImageType = Array)
    img = ilGenImage()
    ilBindImage(img)
    ilLoadL(IL_TYPE_UNKNOWN, lump, sizeof(lump))

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

function colortype()
    bits = ilGetInteger(IL_IMAGE_BITS_PER_PIXEL)
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
    w = Int(ilGetInteger(IL_IMAGE_WIDTH))
    h = Int(ilGetInteger(IL_IMAGE_HEIGHT))
    frames = Int(ilGetInteger(IL_NUM_IMAGES))
    ctype, dcolor, dpix = colortype()
    size = frames == 0 ? (w, h) : (w, h, frames)
    image = Array(ctype, size)
    # TODO return axis array for spatial order, xy?!
    ilCopyPixels(0, 0, 0, w, h, 1, dcolor, dpix, image)
    image
end
