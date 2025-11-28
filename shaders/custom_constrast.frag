#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

uniform sampler2D inputImageTexture;
layout(location = 0) uniform lowp float inputContrast;
layout(location = 1) uniform vec2 screenSize;

vec4 processColor(vec4 sourceColor){
    vec4 result = vec4(((sourceColor.rgb - vec3(0.5)) * inputContrast + vec3(0.5)), sourceColor.w);
    return clamp(result, 0.0, sourceColor.a);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / screenSize;
    lowp vec4 textureColor = texture(inputImageTexture, textureCoordinate);
    vec4 finalColor = processColor(textureColor);
    fragColor = finalColor;
}