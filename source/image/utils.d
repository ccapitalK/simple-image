module image.utils;

import std.exception;
import std.string;

import image.glue;

struct Image {
    ubyte[] data;
    // TODO: Make this const
    int width;
    int height;

    this(size_t width, size_t height) {
        this.width = cast(int) width;
        this.height = cast(int) height;
        data.length = width * height * 4;
    }

    Image dup() const {
        auto im2 = Image(width, height);
        im2.data.length = data.length;
        im2.data[] = data;
        return im2;
    }

    ubyte[] pixel(size_t x, size_t y) @nogc {
        assert(x < width && y < height);
        auto start = 4 * (y * width + x);
        return data[start .. start + 3];
    }

    const(ubyte)[] pixel(size_t x, size_t y) const @nogc {
        assert(x < width && y < height);
        auto start = 4 * (y * width + x);
        return data[start .. start + 3];
    }
}

Image loadImageRgb(string filename) {
    Image im;
    int channels;
    // Load image, forcing 3 channels (RGB)
    ubyte* data = stbi_load(filename.toStringz, &im.width, &im.height, &channels, 4);

    enforce(data != null, () => format("Failed to load \"%s\": %s\n", filename, stbi_failure_reason()));
    im.data[] = 0;
    im.data = data[0 .. 4 * im.width * im.height];

    return im;
}

void writeImageRgb(string filename, Image* im) {
    ubyte[] data;
    data.length = im.width * im.height * 3;
    foreach (y; 0 .. im.height) {
        foreach (x; 0 .. im.width) {
            auto start = 3 * (y * im.width + x);
            data[start ..  start + 3] []= im.pixel(x, y);
        }
    }
    switch (filename[$ - 4 .. $]) {
    case ".bmp":
        stbi_write_bmp(filename.toStringz, im.width, im.height, 3, data.ptr);
        break;
    case ".jpg":
        stbi_write_jpg(filename.toStringz, im.width, im.height, 3, data.ptr, 99);
        break;
    case ".png":
        stbi_write_png(filename.toStringz, im.width, im.height, 3, data.ptr, im.width * 3);
        break;
    default:
        enforce(false, "Unknown file extension");
    }
}
