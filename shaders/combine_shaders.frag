#include <flutter/runtime_effect.glsl>
precision highp float;

out vec4 fragColor;

uniform sampler2D inputImageTexture;

layout(location = 0) uniform lowp float inputExposure;
layout(location = 1) uniform highp float inputContrast;
layout(location = 2) uniform lowp float inputSaturation;
 

layout(location = 3) uniform lowp float inputShadows; // Shadow property of shadow
layout(location = 4) uniform lowp float inputHighlights; // Highlight property of shadow
 
layout(location = 5) uniform lowp float inputTemperature;
layout(location = 6) uniform lowp float inputTint;

layout(location = 7) uniform lowp float inputSharpen;
layout(location = 8) uniform vec2 textureSize;

// Values from \Graphics Shaders: Theory and Practice\ by Bailey and Cunningham
const highp vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
const lowp vec3 warmFilter = vec3(0.93, 0.54, 0.0);
const highp mat3 RGBtoYIQ = mat3(0.299, 0.587, 0.114, 0.596, -0.274, -0.322, 0.212, -0.523, 0.311);
const highp mat3 YIQtoRGB = mat3(1.0, 0.956, 0.621, 1.0, -0.272, -0.647, 1.0, -1.105, 1.702);
 
const highp vec3 luminanceWeightingHS = vec3(0.3, 0.3, 0.3);

float newColor(float v1, float v2) {
    float lr = 2.0 * v1 * v2;
    float gr = 1.0 - 2.0 * (1.0 - v1) * (1.0 - v2);
    return v1 < 0.5 ? lr : gr;
}

vec4 processColorConstrast(vec4 sourceColor){
    return vec4(((sourceColor.rgb - vec3(0.5)) * inputContrast + vec3(0.5)), sourceColor.w);
}

vec4 processColorExposure(vec4 sourceColor){
    return vec4(sourceColor.rgb * pow(2.0, inputExposure), sourceColor.w);
}

vec4 processColorSaturation(vec4 sourceColor){
   lowp float luminance = dot(sourceColor.rgb, luminanceWeighting);
   lowp vec3 greyScaleColor = vec3(luminance);
   return vec4(mix(greyScaleColor, sourceColor.rgb, inputSaturation), sourceColor.w);
}

vec4 processColorHighlightShadow(vec4 sourceColor){
   highp float luminance = dot(sourceColor.rgb, luminanceWeightingHS);
   highp float shadow = clamp((pow(luminance, 1.0/(inputShadows+1.0)) + (-0.76)*pow(luminance, 2.0/(inputShadows+1.0))) - luminance, 0.0, 1.0);
   highp float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-inputHighlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-inputHighlights)))) - luminance, -1.0, 0.0);
   lowp vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + shadow + highlight) - 0.0) * ((sourceColor.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));
   return vec4(result.rgb, sourceColor.a);
}

vec4 processColorHighlight(vec4 sourceColor){
    highp float luminance = dot(sourceColor.rgb, luminanceWeightingHS);
    highp float highlight = clamp((1.0 - (pow(1.0-luminance, 1.0/(2.0-inputHighlights)) + (-0.8)*pow(1.0-luminance, 2.0/(2.0-inputHighlights)))) - luminance, -1.0, 0.0);
    lowp vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + 0.0 + highlight) - 0.0) * ((sourceColor.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));
    return vec4(result.rgb, sourceColor.a);
}

vec4 processColorShadow(vec4 sourceColor){
   highp float luminance = dot(sourceColor.rgb, luminanceWeightingHS);
   highp float shadow = clamp((pow(luminance, 1.0/(inputShadows+1.0)) + (-0.76)*pow(luminance, 2.0/(inputShadows+1.0))) - luminance, 0.0, 1.0);
   lowp vec3 result = vec3(0.0, 0.0, 0.0) + ((luminance + shadow + 0.0) - 0.0) * ((sourceColor.rgb - vec3(0.0, 0.0, 0.0))/(luminance - 0.0));
   return vec4(result.rgb, sourceColor.a);
}

vec4 processColorWhiteBalance(vec4 sourceColor){
   highp vec3 yiq = RGBtoYIQ * sourceColor.rgb; //adjusting inputTint
   yiq.b = clamp(yiq.b + inputTint*0.5226*0.1, -0.5226, 0.5226);
   lowp vec3 rgb = YIQtoRGB * yiq;
   lowp vec3 processed = vec3(
    newColor(rgb.r, warmFilter.r),
    newColor(rgb.g, warmFilter.g),
    newColor(rgb.b, warmFilter.b));
   return vec4(mix(rgb, processed, inputTemperature), sourceColor.a);
}

vec4 processColorSharpen(vec4 sourceColor){
    float neighbor = inputSharpen * -1;
    float center   = inputSharpen * 4 + 1;

    vec3 color =texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 0, FlutterFragCoord().y + 1) / textureSize).rgb * neighbor+ texture(inputImageTexture,
    vec2(FlutterFragCoord().x - 1, FlutterFragCoord().y + 0) / textureSize).rgb * neighbor+ texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 0, FlutterFragCoord().y + 0) / textureSize).rgb * center + texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 1, FlutterFragCoord().y + 0) / textureSize).rgb * neighbor + texture(inputImageTexture,
    vec2(FlutterFragCoord().x + 0, FlutterFragCoord().y - 1) / textureSize).rgb * neighbor;

    return vec4(color, sourceColor.a);
}

void main(){
	vec2 textureCoordinate = FlutterFragCoord().xy / textureSize;
	vec4 textureColor = texture(inputImageTexture, textureCoordinate);
    vec4 sharpen = processColorSharpen(textureColor);
    vec4 highLightShadow = processColorHighlightShadow(sharpen);
	vec4 constrast = processColorConstrast(highLightShadow);
	vec4 exposure = processColorExposure(constrast);
	vec4 saturation = processColorSaturation(exposure);
	vec4 whiteBalance = processColorWhiteBalance(saturation);
    fragColor = whiteBalance;
}



