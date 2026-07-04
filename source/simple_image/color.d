module simple_image.color;

import std.math;

private T clamp(T)(T v, T min, T max) => v < min ? min : (v > max ? max : v);

/// Weights for luminance as defined by Rec. 709
immutable float[3] REC709_GRAYSCALE_WEIGHTS = [0.2126, 0.7152, 0.0722];

/// Perceputal greyscale luminance of color. NEEDS TO BE IN LINEAR COLOR SPACE, DON'T USE ON SRGB.
float luminanceFromLinear(float[3] v) pure nothrow @nogc @safe {
    float x = 0;
    foreach (i; 0 .. 3) {
        x += REC709_GRAYSCALE_WEIGHTS[i] * v[i];
    }
    return x;
}

/// Perceptual greyscale luminance of srgb color (color space that images are normally encoded in). Output is in
/// linear (0 - 1) color space
float luminance(ubyte[3] srgbColors) pure nothrow @nogc @safe {
    return luminanceFromLinear([
        srgbColors[0].srgbUnormToLinearF32,
        srgbColors[1].srgbUnormToLinearF32,
        srgbColors[2].srgbUnormToLinearF32,
    ]);
}

/// Convert a 8 bit color value to floating point, treating it as UNORM encoded (maps linearly, with 255 -> 1.0).
/// This is the convention for 8 bit color representation that almost all graphics apis/libraries have converged on.
/// Agnostic of color space.
float unormToF32(ubyte v) pure nothrow @nogc @safe {
    enum INV255 = 1.0 / 255.0;
    return (cast(float) v) * INV255;
}

/// Convert a floating point color value to 8 biit unsigned, encoding it as UNORM (maps linearly, with 255 -> 1.0).
/// This is the convention for 8 bit color representation that almost all graphics apis/libraries have converged on.
/// Agnostic of color space.
ubyte f32ToUnorm(float v) pure nothrow @nogc @safe {
    return cast(ubyte) (v.clamp(0, 1) * 255).round();
}

/// Convert a color value (0 - 1) in srgb space to the matching value in linear color space.
float srgbToLinear(float v) pure nothrow @nogc @safe {
    v = v.clamp(0, 1);
    enum INV12_92 = 1.0 / 12.92;
    enum INV1_055 = 1.0 / 1.055;
    if (v <= 0.04045) {
        return v * INV12_92;
    } else {
        return ((v + 0.055) * INV1_055).pow(2.4);
    }
}

/// Decode an srgb unorm value (the normal convention for colors at rest) to linear floating point
float srgbUnormToLinearF32(ubyte c) pure nothrow @nogc @safe => c.unormToF32().srgbToLinear();

/// Convert a color value (0 - 1) in linear space to the matching value in srgb color space.
float linearToSrgb(float v) pure nothrow @nogc @safe {
    v = v.clamp(0, 1);
    if (v <= 0.0031308) {
        return v * 12.92;
    } else {
        return 1.055 * pow(v, 1 / 2.4) - 0.055;
    }
}

/// Encode a linear floating point color value as an srgb unorm value (the normal convention for colors at rest).
ubyte linearF32ToSrgbUnorm(float v) pure nothrow @nogc @safe => v.linearToSrgb().f32ToUnorm();

unittest {
    // unormToF32
    assert(unormToF32(0) == 0f);
    assert(unormToF32(255) == 1f);
    assert(isClose(unormToF32(128), 128f / 255f, 1e-6));
    foreach (ubyte u; 0 .. 255)
        assert(unormToF32(cast(ubyte)(u + 1)) > unormToF32(u));

    // f32ToUnorm
    assert(f32ToUnorm(0f) == 0);
    assert(f32ToUnorm(.5f) == 128);
    assert(f32ToUnorm(.499999f) == 127);
    assert(f32ToUnorm(1f) == 255);
    assert(f32ToUnorm(-0.1f) == 0);
    assert(f32ToUnorm(1.02f) == 255);

    // Round trip
    foreach (ubyte u; 0 .. 256) {
        assert(u.unormToF32().f32ToUnorm() == u);
        assert(u.unormToF32().f32ToUnorm() == u);
        assert(u.srgbUnormToLinearF32().linearF32ToSrgbUnorm() == u);
    }
    foreach (i; 0 .. 101) {
        float v = i / 100.0f;
        assert(isClose(v.linearToSrgb().srgbToLinear(), v, 1e-6));
    }
}
