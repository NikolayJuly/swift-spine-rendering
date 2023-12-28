#ifndef SpineSharedStructs_h
#define SpineSharedStructs_h

#include <simd/simd.h>

#import "CommonStructs.h"

typedef struct {
    simd_float3 position;
    simd_float2 uv;

    char textureIndex;

    simd_uchar4 tintColor;

} TexturedVertex2D;

typedef struct {
    float width; // widest size, as we assume landscape usage
    float height;
} ScreenSize;

typedef struct {
    simd_float2 origin;
    simd_float2 size;
} ScreenFrame;

#endif /* SpineSharedStructs_h */
