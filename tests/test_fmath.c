#include "tinytest.h"

#include <math.h>
#include <stdint.h>
#include <string.h>

static float fract(float f) {
    return f - floorf(f);
}

static float clamp(float d, float min, float max) {
    float t = d < min ? min : d;
    return t > max ? max : t;
}

static float mix(float min, float max, float amount) {
    return min + (max - min) * amount;
}

static float dot_product(float *a, float *b)
{
    float sum = 0;
    int n = 4;

    for (int i = 0; i < n; i++) {
        sum += a[i] * b[i];
    }

    return sum;
}

static void fract_vec4(float *f, float *output) {
    output[0] = fract(f[0]);
    output[1] = fract(f[1]);
    output[2] = fract(f[2]);
    output[3] = fract(f[3]);
}

static void mult_vec4_float(float *v, float k, float *output) {
    output[0] = v[0] * k;
    output[1] = v[1] * k;
    output[2] = v[2] * k;
    output[3] = v[3] * k;
}

//
// Encode a floating point number to RGBA in a [-32768, 32768 ) range.
//

void encode_rgba32_float(float f, uint8_t *out) {
    double d = (double) f;
    uint32_t u = (uint32_t) (floor(d * 65536.0) + 2147483648.0);
    out[0] = (u & 0xff000000) >> 24;
    out[1] = (u & 0x00ff0000) >> 16;
    out[2] = (u & 0x0000ff00) >> 8;
    out[3] = (u & 0x000000ff);
}

void convert_rgba32_to_vec4(uint8_t *in, float *out) {
    out[0] = in[0] / 255.0f;
    out[1] = in[1] / 255.0f;
    out[2] = in[2] / 255.0f;
    out[3] = in[3] / 255.0f;
}

// u[4] in [0..1] range
float decode_rgba32_float(float *u) {
    return (u[0] * 255.0f * 16777216.0f + u[1] * 255.0f * 65536.0f + u[2] * 255.0f * 256.0f + u[3] * 255.0f - 2147483648.0f) / 65536.0f;
}

void test_rgba32_float()
{
    float v4[4];
    uint8_t rgba[4];
    float epsilon = 0.002f;

    for (float i = -32768.0f; i < 32768.0f; i += 0.1f) {
        memset(v4, 0, sizeof v4);
        memset(rgba, 0, sizeof rgba);

        float f = i + 0.05678f + fabsf(i) / 50000.0f;
        if (f >= 32768.0f) continue;

        encode_rgba32_float(f, rgba);
        convert_rgba32_to_vec4(rgba, v4);
        float t = decode_rgba32_float(v4);

        // printf("%f %f\n", f, t);

        ASSERT("Encoded and decoded numbers equals", fabsf(t - f) < epsilon);
    }
}

//
// Encode a floating point number to RGBA in a predefined range
// * NOT USED
//

// https://stackoverflow.com/questions/18453302/how-do-you-pack-one-32bit-int-into-4-8bit-ints-in-glsl-webgl
void encode_range(float value, float min_value, float max_value, float *output)
{
    value = clamp( (value - min_value) / (max_value - min_value), 0.0f, 1.0f );
    value *= (256.0f * 256.0f * 256.0f - 1.0f) / (256.0f * 256.0f * 256.0f);

    float encode[4] = { 1.0f, 256.0f, 256.0f * 256.0f, 256.0f * 256.0f * 256.0f };
    mult_vec4_float(encode, value, encode);
    fract_vec4(encode, encode);

    output[0] = encode[0] - encode[1] / 256.0f + 1.0f / 512.0f;
    output[1] = encode[1] - encode[2] / 256.0f + 1.0f / 512.0f;
    output[2] = encode[2] - encode[3] / 256.0f + 1.0f / 512.0f;
    output[3] = encode[3] + 1.0f / 512.0f;
}

void encode_fract(float value, float *output)
{
    encode_range(value, 0, 1, output);
}

float decode_range(float *pack, float min_value, float max_value)
{
    float dec[4] = { 1.0f / 1.0f, 1.0f / 256.0f, 1.0f / (256.0f * 256.0f), 1.0f / (256.0f * 256.0f * 256.0f) };
    float value = dot_product(pack, dec);
    value = value * (256.0f * 256.0f * 256.0f) / (256.0f * 256.0f * 256.0f - 1.0f);
    return mix(min_value, max_value, value);
}

float decode_fract(float *pack)
{
    return decode_range(pack, 0, 1);
}

void encode_rgba56_float(float f, uint8_t *output) {
    float integer = floorf(f);
    float fraction = fabsf(f - integer);

    float vec4[4];
    encode_fract(fraction, vec4);
    output[0] = vec4[0] * 255.0f;
    output[1] = vec4[1] * 255.0f;
    output[2] = vec4[2] * 255.0f;
    output[3] = vec4[3] * 255.0f;

    int u = ((int) integer & 0x00ffffff) + 8388608;
    output[4] = (u & 0x00ff0000) >> 16;
    output[5] = (u & 0x0000ff00) >> 8;
    output[6] = (u & 0x000000ff);
}

float decode_rgba56_float(float *rgbaxyz) {
    float fraction = decode_fract(rgbaxyz);
    float integer = (rgbaxyz[4] * 255.0f * 256.0f * 256.0f + rgbaxyz[5] * 255.0f * 256.0f + rgbaxyz[6] * 255.0f) - 8388608.0f;
    return integer + fraction;
}

void test_rgba56_float() {
    float epsilon = 0.002f;

    for (float i = -32768.0f; i < 32768.0f; i += 0.1f) {
        float f = i + 0.05678f + fabsf(i) / 50000.0f;
        if (f >= 32768.0f) continue;

        uint8_t encoded[7];
        encode_rgba56_float(f, encoded);

        float rgbaxyz[7];
        rgbaxyz[0] = encoded[0] / 255.0f;
        rgbaxyz[1] = encoded[1] / 255.0f;
        rgbaxyz[2] = encoded[2] / 255.0f;
        rgbaxyz[3] = encoded[3] / 255.0f;
        rgbaxyz[4] = encoded[4] / 255.0f;
        rgbaxyz[5] = encoded[5] / 255.0f;
        rgbaxyz[6] = encoded[6] / 255.0f;

        float t = decode_rgba56_float(rgbaxyz);
        // printf("%f %f\n", f, t);

        ASSERT("Encoded and decoded numbers equals", fabsf(t - f) < epsilon);
    }
}

int main()
{
    RUN(test_rgba32_float);
    RUN(test_rgba56_float);
    return TEST_REPORT();
}
