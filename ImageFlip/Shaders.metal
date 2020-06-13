#include <metal_stdlib>
using namespace metal;
namespace mtlswift {}

constant bool deviceSupportsNonuniformThreadgroups [[ function_constant(0) ]];

#define checkPosition(position, textureSize, deviceSupportsNonuniformThreadgroups) \
if (!deviceSupportsNonuniformThreadgroups) {                                       \
    if (position.x >= textureSize.x || position.y >= textureSize.y) {              \
        return;                                                                    \
    }                                                                              \
}

/// mtlswift:dispatch:optimal(0):over:destination
kernel void textureFlip(texture2d<half, access::read> source [[ texture(0) ]],
                        texture2d<half, access::write> destination [[ texture(1) ]],
                        ushort2 position [[thread_position_in_grid]]) {
    const auto textureSize = ushort2(destination.get_width(),
                                     destination.get_height());
    checkPosition(position,
                  textureSize,
                  deviceSupportsNonuniformThreadgroups);

    const auto readPosition = ushort2(textureSize.x - position.x,
                                      position.y);
    half4 sourceColor = source.read(readPosition);
    destination.write(sourceColor, position);
}
