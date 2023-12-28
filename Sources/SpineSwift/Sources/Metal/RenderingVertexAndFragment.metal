#include <metal_stdlib>

#import "SpineSharedStructs.h"

#import "CommonStructs.h"

using namespace metal;

struct VertexInOut
{
    float4 position [[ position ]];
    float2 textureCoordinate;
    char textureIndex;

    half4 tintColor;
};

vertex VertexInOut draw_triangles_vertex(const device TexturedVertex2D *vertex_array  [[ buffer(0) ]],
                                         constant ScreenFrame          &screenFrame   [[ buffer(1) ]],
                                         unsigned int                  vid            [[ vertex_id ]]) {
    float scaleW = 2.0/screenFrame.size[0];
    float scaleH = 2.0/screenFrame.size[1];
    TexturedVertex2D vertex2d = vertex_array[vid];
    packed_float2 transformedVertex = packed_float2(scaleW * (vertex2d.position.x - screenFrame.origin[0]) - 1.0,
                                                    scaleH * (vertex2d.position.y - screenFrame.origin[1]) - 1.0);

    simd_uchar4 tc = vertex2d.tintColor;

    VertexInOut vertexInOut;
    vertexInOut.position = float4(transformedVertex, vertex2d.position.z, 1.0);
    vertexInOut.textureCoordinate = float2(vertex2d.uv[0], vertex2d.uv[1]);
    vertexInOut.textureIndex = vertex2d.textureIndex;

    vertexInOut.tintColor = half4(half(tc.r)/255.0, half(tc.g)/255.0, half(tc.b)/255.0, half(tc.a)/255.0);
    return vertexInOut;
}

fragment half4 draw_triangles_fragment(VertexInOut                                     inFrag                   [[ stage_in ]],
                                       const array<texture2d<half, access::sample>, 5> imageTexture             [[ texture(0) ]],
                                       device uchar                                    *outlineBufferSource     [[ buffer(0) ]],
                                       constant BufferDimensions                       &outlineDimensions       [[ buffer(1) ]]) {
    constexpr sampler textureSampler (mag_filter::nearest,
                                      min_filter::nearest);

    // Sample the texture to obtain a color
    const half4 colorSample = imageTexture[inFrag.textureIndex].sample(textureSampler, inFrag.textureCoordinate);

    if (colorSample[3] < 0.1) {
        discard_fragment();
    }

    return colorSample * inFrag.tintColor;
}

