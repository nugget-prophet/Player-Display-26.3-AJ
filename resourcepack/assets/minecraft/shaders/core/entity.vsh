#version 330
#extension GL_ARB_separate_shader_objects : require

#if defined(PER_FACE_LIGHTING) || !defined(NO_CARDINAL_LIGHTING)
#include <minecraft:light.glsl>
#endif
#include <minecraft:fog.glsl>
#include <minecraft:dynamictransforms.glsl>
#include <minecraft:projection.glsl>
#include <minecraft:sample_lightmap.glsl>


uniform sampler2D Sampler0;


#define SPD_SPLITMODEL 0
#if SPD_SPLITMODEL == 1
#define SPD_MAXPART 10
#else
#define SPD_MAXPART 5
#endif
#define SPD_SPACING 1024.0
#define SPD_MAXRANGE (0.5 * SPD_SPACING)
#define SPD_SKINRES 64

void spd_apply(inout vec3 pos, out ivec2 partInfo) {
    partInfo = ivec2(0);
    ivec2 dim = textureSize(Sampler0, 0);
  
    if (!(abs(ProjMat[2][3]) > 10e-6 && dim.x == SPD_SKINRES && dim.y == SPD_SKINRES
          && FogRenderDistanceEnd > FogRenderDistanceStart)) {
        return;
    }
    int part = -int((pos.y - SPD_MAXRANGE) / SPD_SPACING);
    if (part < 1 || part > SPD_MAXPART) {
        return;
    }

  
    vec4 samp1 = texelFetch(Sampler0, ivec2(54, 20), 0);
    vec4 samp2 = texelFetch(Sampler0, ivec2(55, 20), 0);
    bool slim = samp1.a == 0.0 || (((samp1.r + samp1.g + samp1.b) == 0.0)
        && ((samp2.r + samp2.g + samp2.b) == 0.0) && samp1.a == 1.0 && samp2.a == 1.0);
    partInfo = ivec2(part, slim ? 1 : 0);
    pos.y += SPD_SPACING * float(part);
}


layout(location = 0) in vec3 Position;
layout(location = 1) in vec4 Color;
layout(location = 2) in vec2 UV0;
layout(location = 3) in ivec2 UV1;
layout(location = 4) in ivec2 UV2;
layout(location = 5) in vec3 Normal;

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler1;
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
uniform sampler2D Sampler2;
#endif

layout(location = 0) out float sphericalVertexDistance;
layout(location = 1) out float cylindricalVertexDistance;

#ifdef PER_FACE_LIGHTING
layout(location = 2) out vec4 vertexPerFaceColorBack;
layout(location = 3) out vec4 vertexPerFaceColorFront;
#else
layout(location = 2) out vec4 vertexColor;
#endif

#ifndef EMISSIVE
layout(location = 4) out vec4 lightMapColor;
#endif

#ifndef NO_OVERLAY
layout(location = 5) out vec4 overlayColor;
#endif

layout(location = 6) out vec2 texCoord0;
#ifdef GLINT
layout(location = 7) out vec2 texCoordGlint;
#endif

layout(location = 8) flat out ivec2 spdPartInfo;
layout(location = 9) out vec2 spdHeadUV;

void main() {
    vec3 pos = Position;
    vec2 uv0 = UV0;
    spd_apply(pos, spdPartInfo);
    spdHeadUV = UV0;

    gl_Position = ProjMat * ModelViewMat * vec4(pos, 1.0);

    sphericalVertexDistance = fog_spherical_distance(pos);
    cylindricalVertexDistance = fog_cylindrical_distance(pos);

#ifdef PER_FACE_LIGHTING
    vec2 light = minecraft_compute_light(Light0_Direction, Light1_Direction, Normal);
    vertexPerFaceColorBack = minecraft_mix_light_separate(-light, Color);
    vertexPerFaceColorFront = minecraft_mix_light_separate(light, Color);
#elif defined(NO_CARDINAL_LIGHTING)
    vertexColor = Color;
#else
    vertexColor = minecraft_mix_light(Light0_Direction, Light1_Direction, Normal, Color);
#endif

#if !defined(EMISSIVE) && !defined(OIT_ALPHA_ONLY)
    lightMapColor = sample_lightmap(Sampler2, UV2);
#endif

#if !defined(NO_OVERLAY) && !defined(OIT_ALPHA_ONLY)
    overlayColor = texelFetch(Sampler1, UV1, 0);
#endif

    texCoord0 = uv0;

#ifdef APPLY_TEXTURE_MATRIX
    texCoord0 = (TextureMat * vec4(uv0, 0.0, 1.0)).xy;
#endif

#ifdef GLINT
    texCoordGlint = (TextureMat * vec4(uv0, 0.0, 1.0)).xy;
#endif
}
