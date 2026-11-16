#version 330
#extension GL_ARB_separate_shader_objects : require

#ifdef GLINT
#include <minecraft:globals.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:oit.glsl>

uniform sampler2D Sampler0;

#ifdef DISSOLVE
uniform sampler2D DissolveMaskSampler;
#endif

#ifdef GLINT
uniform sampler2D GlintSampler;
#endif

layout(location = 0) in float sphericalVertexDistance;
layout(location = 1) in float cylindricalVertexDistance;
#ifdef PER_FACE_LIGHTING
layout(location = 2) in vec4 vertexPerFaceColorBack;
layout(location = 3) in vec4 vertexPerFaceColorFront;
#else
layout(location = 2) in vec4 vertexColor;
#endif

#ifndef EMISSIVE
layout(location = 4) in vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
layout(location = 5) in vec4 overlayColor;
#endif

layout(location = 6) in vec2 texCoord0;
#ifdef GLINT
layout(location = 7) in vec2 texCoordGlint;
#endif
layout(location = 8) flat in ivec2 spdPartInfo;
layout(location = 9) in vec2 spdHeadUV;


#define SPD_SPLITMODEL 0
#define SPD_SKINRES 64

const vec4[] spd_subuvs = vec4[](
    vec4(4.0,  0.0,  8.0,  4.0 ), // 4x4x12
    vec4(8.0,  0.0,  12.0, 4.0 ),
    vec4(0.0,  4.0,  4.0,  16.0),
    vec4(4.0,  4.0,  8.0,  16.0),
    vec4(8.0,  4.0,  12.0, 16.0),
    vec4(12.0, 4.0,  16.0, 16.0),
    vec4(4.0,  0.0,  7.0,  4.0 ), // 4x3x12
    vec4(7.0,  0.0,  10.0, 4.0 ),
    vec4(0.0,  4.0,  4.0,  16.0),
    vec4(4.0,  4.0,  7.0,  16.0),
    vec4(7.0,  4.0,  11.0, 16.0),
    vec4(11.0, 4.0,  14.0, 16.0),
    vec4(4.0,  0.0,  12.0, 4.0 ), // 4x8x12
    vec4(12.0, 0.0,  20.0, 4.0 ),
    vec4(0.0,  4.0,  4.0,  16.0),
    vec4(4.0,  4.0,  12.0, 16.0),
    vec4(12.0, 4.0,  16.0, 16.0),
    vec4(16.0, 4.0,  24.0, 16.0)
);

const vec2[] spd_origins = vec2[](
    vec2(40.0, 16.0), // right arm
    vec2(40.0, 32.0),
    vec2(32.0, 48.0), // left arm
    vec2(48.0, 48.0),
    vec2(16.0, 16.0), // torso
    vec2(16.0, 32.0),
    vec2(0.0,  16.0), // right leg
    vec2(0.0,  32.0),
    vec2(16.0, 48.0), // left leg
    vec2(0.0,  48.0)
);


bool spd_map_uv(out vec2 skinUV, out vec2 underUV, out bool outerLayer) {
    skinUV = texCoord0;
    underUV = texCoord0;
    outerLayer = false;
    if (spdPartInfo.x == 0) return false;

    vec2 pixel = spdHeadUV * float(SPD_SKINRES);
    if (pixel.x < 0.0 || pixel.x >= 64.0 || pixel.y < 0.0 || pixel.y >= 16.0) return false;
    int layer = pixel.x >= 32.0 ? 1 : 0;
    pixel.x -= 32.0 * float(layer);
    ivec2 cell = ivec2(floor(pixel / 8.0));
    int face;
    if (cell.y == 0) {
        if (cell.x != 1 && cell.x != 2) return false;
        face = cell.x - 1; // top, bottom
    } else {
        face = cell.x + 2; // right, front, left, back
    }
    vec2 corner = (pixel - vec2(cell) * 8.0) / 8.0;
    int part = spdPartInfo.x - 1;
    int bodyPart = part % 5;
    int subuvIndex = face;
    if (spdPartInfo.y != 0 && (bodyPart == 0 || bodyPart == 1)) {
        subuvIndex += 6;
    } else if (bodyPart == 2) {
        subuvIndex += 12;
    }
    vec4 rect = spd_subuvs[subuvIndex];
#if SPD_SPLITMODEL == 1

    if (face >= 2) {
        rect.w -= 6.0;
        if (part >= 5) rect.yw += 6.0;
    }
#endif
    vec2 offset = mix(rect.xy, rect.zw, corner);
    skinUV = (spd_origins[2 * bodyPart + layer] + offset) / float(SPD_SKINRES);
    underUV = (spd_origins[2 * bodyPart] + offset) / float(SPD_SKINRES);
    outerLayer = layer == 1;
    return true;
}


#define SPD_OUTER_FADE
#define SPD_FADERANGE 12.0
#define SPD_FADEBIAS 8.0
#define SPD_MINALPHA 0.25

const mat4 spd_bayer4 = mat4( 0.0 / 16.0,  8.0 / 16.0,  2.0 / 16.0, 10.0 / 16.0,
                             12.0 / 16.0,  4.0 / 16.0, 14.0 / 16.0,  6.0 / 16.0,
                              3.0 / 16.0, 11.0 / 16.0,  1.0 / 16.0,  9.0 / 16.0,
                             15.0 / 16.0,  7.0 / 16.0, 13.0 / 16.0,  5.0 / 16.0);


#ifndef OIT_ALPHA_ONLY
layout(location = 0) out vec4 fragColor;
#endif

vec4 calculateFinalColor(vec4 color, vec2 skinUV, bool spdMapped) {
    #ifndef NO_OVERLAY
    color.rgb = mix(overlayColor.rgb, color.rgb, overlayColor.a);
    #endif

    #ifndef EMISSIVE
    color *= lightMapColor;
    #endif

    #ifdef GLINT
    vec2 glintUV = texCoordGlint;
    if (spdMapped) glintUV = (TextureMat * vec4(skinUV, 0.0, 1.0)).xy;
    vec4 glintColor = GlintAlpha * texture(GlintSampler, glintUV);

    color.rgb += glintColor.rgb * glintColor.rgb;
    #endif

    #ifdef OIT_ACCUMULATE
    color = sampleColorForAccumulation(color);
    vec4 fogColor = vec4(FogColor.rgb * color.a, FogColor.a);
    #else
    vec4 fogColor = FogColor;
    #endif

    return apply_fog(color, sphericalVertexDistance, cylindricalVertexDistance, FogEnvironmentalStart, FogEnvironmentalEnd, FogRenderDistanceStart, FogRenderDistanceEnd, fogColor);
}

void main() {
    vec2 skinUV;
    vec2 underUV;
    bool outerLayer;
    bool spdMapped = spd_map_uv(skinUV, underUV, outerLayer);
    vec2 sampleUV = skinUV;
    #ifdef APPLY_TEXTURE_MATRIX
    if (spdMapped) sampleUV = (TextureMat * vec4(skinUV, 0.0, 1.0)).xy;
    #endif
    vec4 color = texture(Sampler0, sampleUV);

    if (spdMapped && color.a <= 0.0) discard;

    #ifdef OIT_ADDITIVE
    color.a = min(0.99, color.a);
    #endif

    #ifdef ALPHA_CUTOUT
    if (color.a < ALPHA_CUTOUT) {
        discard;
    }
    #endif

    #ifdef PER_FACE_LIGHTING
    vec4 faceVertexColor = gl_FrontFacing ? vertexPerFaceColorFront : vertexPerFaceColorBack;
    #else
    vec4 faceVertexColor = vertexColor;
    #endif

    #ifdef DISSOLVE
    if (faceVertexColor.a < texture(DissolveMaskSampler, sampleUV).a) {
        discard;
    }

    faceVertexColor.a = 1.0;
    #endif

    color *= faceVertexColor * ColorModulator;

  
    #ifdef SPD_OUTER_FADE


    if (spdMapped && outerLayer && color.a > 0.0 && color.a < 1.0) {
        color.a = max(color.a, SPD_MINALPHA);
        float fade = mix(color.a, 1.0, clamp((cylindricalVertexDistance - SPD_FADEBIAS) / (SPD_FADERANGE - SPD_FADEBIAS), 0.0, 1.0));
        if (fade < spd_bayer4[int(gl_FragCoord.x) % 4][int(gl_FragCoord.y) % 4] + (0.5 / 16.0)) {
            discard;
        }
        #ifndef OIT_ALPHA_ONLY
 
        vec3 underCol = texture(Sampler0, underUV).rgb * faceVertexColor.rgb * ColorModulator.rgb;
        vec3 trueMix = mix(underCol, color.rgb, color.a);
        color.rgb = (trueMix - (1.0 - fade) * underCol) / fade;
        #endif
        color.a = 1.0;
    }
    #endif


    #ifdef GLINT
    color.a = max(color.a, GlintAlpha);
    #endif

    #ifdef OIT_ALPHA_ONLY
    executeAlphaOnlyPhase(gl_FragCoord.z, color.a);
    #else
    fragColor = calculateFinalColor(color, skinUV, spdMapped);
    #endif
}
