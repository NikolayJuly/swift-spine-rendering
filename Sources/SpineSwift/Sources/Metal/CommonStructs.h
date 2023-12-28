#ifndef MetalExtension_CommonStructs_h
#define MetalExtension_CommonStructs_h

#if MACOS
#include <stdint.h>
#endif

typedef struct {
    int32_t width;
    int32_t height;
} BufferDimensions;

typedef BufferDimensions IntSize;

typedef struct {
    int32_t x;
    int32_t y;
} IntPosition;

typedef struct {
    IntPosition origin;
    IntSize size;
} IntRect;

#endif /* MetalExtension_CommonStructs_h */
