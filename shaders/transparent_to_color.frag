 

#include <flutter/runtime_effect.glsl>

precision highp float;

out vec4 fragColor;

uniform sampler2D inputImageTexture;
layout(location = 0) uniform vec3 inputColor; 
layout(location = 1) uniform vec2 screenSize;

const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

void main() {
  vec2 textureCoordinate = FlutterFragCoord().xy / screenSize;
  lowp vec4 textureColor = texture(inputImageTexture, textureCoordinate); 
  if(textureColor.a == 0.0){
    float luminance = dot(textureColor.rgb, luminanceWeighting); 
    fragColor = vec4(mix(inputColor.rgb, textureColor.rgb, luminance), 1.0);
  }else{
    fragColor = textureColor;
  }
}
