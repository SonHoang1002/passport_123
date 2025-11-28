#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

uniform sampler2D inputImageTexture;
layout(location = 0) uniform lowp float inputSharpen;
layout(location = 1) uniform vec2 screenSize;

vec4 processColor(vec4 sourceColor){

    float neighbor = inputSharpen * -1;
    float center   = inputSharpen * 4 + 1;

    vec3 color =texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 0, FlutterFragCoord().y + 1) / screenSize).rgb * neighbor+ texture(inputImageTexture,
    vec2(FlutterFragCoord().x - 1, FlutterFragCoord().y + 0) / screenSize).rgb * neighbor+ texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 0, FlutterFragCoord().y + 0) / screenSize).rgb * center + texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 1, FlutterFragCoord().y + 0) / screenSize).rgb * neighbor + texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 0, FlutterFragCoord().y - 1) / screenSize).rgb * neighbor;

    return vec4(color, sourceColor.a);
}

void main() {
    vec2 textureCoordinate = FlutterFragCoord().xy / screenSize;
    lowp vec4 textureColor = texture(inputImageTexture, textureCoordinate);
    vec4 finalColor = processColor(textureColor);
    fragColor = finalColor;
}
