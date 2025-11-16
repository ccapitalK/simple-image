module simple_image.utils;

import std.exception;
import std.string;

import glue = _image_glue;

struct Image {
    enum PIXEL_STRIDE = 4;
    // Stored as rgba8 data internally
    ubyte[] data;
    // TODO: Make this const
    int width;
    int height;

    this(size_t width, size_t height) {
        this.width = cast(int) width;
        this.height = cast(int) height;
        data.length = width * height * PIXEL_STRIDE;
    }

    this(size_t width, size_t height, ubyte[] data) {
        enforce(data.length == width * height * PIXEL_STRIDE);
        this.width = cast(int) width;
        this.height = cast(int) height;
        this.data = data;
    }

    Image dup() const {
        auto im2 = Image(width, height);
        im2.data.length = data.length;
        im2.data[] = data;
        return im2;
    }

    ubyte[] pixel(size_t x, size_t y) @nogc {
        assert(x < width && y < height);
        auto start = PIXEL_STRIDE * (y * width + x);
        return data[start .. start + 3];
    }

    const(ubyte)[] pixel(size_t x, size_t y) const @nogc {
        assert(x < width && y < height);
        auto start = PIXEL_STRIDE * (y * width + x);
        return data[start .. start + 3];
    }

    ubyte *unsafeGetBufPtr() => data.ptr;
}

enum AllocationStrategy {
    gc,
    malloc,
}

struct LoadImageConfig {
    AllocationStrategy allocStrategy = AllocationStrategy.gc;
}

Image loadImageRgb(string filename, LoadImageConfig config = LoadImageConfig()) {
    Image im;
    int channels;
    // Load image, forcing 3 channels (RGB)
    ubyte* data = glue.stbi_load(filename.toStringz, &im.width, &im.height, &channels, Image.PIXEL_STRIDE);

    // TODO: Pass in an allocator callback to stb, instead of copying
    enforce(data != null,
        new Exception(format("Failed to load \"%s\": %s\n", filename, glue.stbi_failure_reason().fromStringz)));
    final switch (config.allocStrategy) {
    case AllocationStrategy.gc:
        im.data = new ubyte[Image.PIXEL_STRIDE * im.width * im.height];
        im.data[] = data[0 .. Image.PIXEL_STRIDE * im.width * im.height];
        glue.stbi_image_free(data);
        break;
    case AllocationStrategy.malloc:
        im.data = data[0 .. Image.PIXEL_STRIDE * im.width * im.height];
        break;
    }

    return im;
}

unittest {
    assertThrown(loadImageRgb("/tmp/doesn'texist"));
}

void writeImageRgb(Image im, string filename) {
    ubyte[] data;
    data.length = im.width * im.height * 3;
    foreach (y; 0 .. im.height) {
        foreach (x; 0 .. im.width) {
            auto start = 3 * (y * im.width + x);
            data[start .. start + 3][] = im.pixel(x, y);
        }
    }
    switch (filename[$ - 4 .. $]) {
    case ".bmp":
        glue.stbi_write_bmp(filename.toStringz, im.width, im.height, 3, data.ptr);
        break;
    case ".jpg":
        glue.stbi_write_jpg(filename.toStringz, im.width, im.height, 3, data.ptr, 99);
        break;
    case ".png":
        glue.stbi_write_png(filename.toStringz, im.width, im.height, 3, data.ptr, im.width * 3);
        break;
    default:
        enforce(false, "Unknown file extension");
    }
}
