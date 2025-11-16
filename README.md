# Simple-Image

A D wrapper library for stb-image and stb-image-write. Example Usage:

```D
import simple_image;

void main(string[] args) {
    auto image = args[1].loadImageRgb();
    enum TILE_WIDTH = 24;
    foreach(y; 0 .. image.height) {
        foreach(x; 0 .. image.width) {
            // Draw blue checkboard on top of image
            if (((x / TILE_WIDTH) ^ (y / TILE_WIDTH)) & 1) continue;
            image.pixel(x, y)[] []= [0, 0, 255];
        }
    }
    image.writeImageRgb(args[2]);
}
```
