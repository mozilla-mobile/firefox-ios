// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


//
//  blurredPoints.metal
//  OHarkonnen
//
//  Created by Nishant Bhasin on 2025-03-11.
//
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut milky_way_vertex(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        {-1, -1},  // Bottom-left
        { 1, -1},  // Bottom-right
        {-1,  1},  // Top-left
        { 1,  1}   // Top-right
    };
    
    float2 texCoords[4] = {
        {0, 0},  // Bottom-left
        {1, 0},  // Bottom-right
        {0, 1},  // Top-left
        {1, 1}   // Top-right
    };
    
    VertexOut out;
    out.position = float4(positions[vertexID], 0, 1);
    out.texCoord = texCoords[vertexID];
    return out;
}

// ✅ Made static to avoid linker conflicts
static float random(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    
    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    
    float2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (b - a) * u.x;
}

fragment half4 milky_way_fragment(VertexOut in [[stage_in]],
                                  constant float &time [[buffer(0)]],
                                  texture2d<half> previousFrame [[texture(0)]]) {
    // Five animated control points
    float2 p1 = float2(0.2 + 0.2 * sin(time * 0.8), 0.3 + 0.2 * cos(time * 0.8));
    float2 p2 = float2(0.8 + 0.2 * cos(time * 0.6), 0.7 + 0.2 * sin(time * 0.6));
    float2 p3 = float2(0.6 + 0.2 * sin(time * 1.5), 0.3 + 0.2 * cos(time * 1.5));
    float2 p4 = float2(0.4 + 0.2 * cos(time * 1.1), 0.6 + 0.2 * sin(time * 1.1));
    float2 p5 = float2(0.7 + 0.2 * sin(time * 0.9), 0.5 + 0.2 * cos(time * 0.9));
    
    // Colors for each control point
    half3 color1 = half3(1.0, 0.47, 0.2);
    half3 color2 = half3(0.2, 0.55, 1.0);
    half3 color3 = half3(1.0, 0.31, 0.12);
    half3 color4 = half3(0.5, 1.0, 0.4);
    half3 color5 = half3(0.8, 0.2, 0.6);
    
    // Pulsating effect
    float sizeMod = 0.1 + 0.05 * sin(time * 1.2);
    float maxDistance = 0.725 + sizeMod;
    
    // Influence calculation
    float d1 = pow(max(1.0 - distance(in.texCoord, p1) / maxDistance, 0.0), 2.0);
    float d2 = pow(max(1.0 - distance(in.texCoord, p2) / maxDistance, 0.0), 2.0);
    float d3 = pow(max(1.0 - distance(in.texCoord, p3) / maxDistance, 0.0), 2.0);
    float d4 = pow(max(1.0 - distance(in.texCoord, p4) / maxDistance, 0.0), 2.0);
    float d5 = pow(max(1.0 - distance(in.texCoord, p5) / maxDistance, 0.0), 2.0);
    
    // Add Perlin noise to influence size
    float noiseMod = noise(in.texCoord * 10.0 + time) * 0.1;
    maxDistance += noiseMod;
    
    // Normalize weights
    float totalWeight = d1 + d2 + d3 + d4 + d5;
    if (totalWeight > 0.001) {
        d1 /= totalWeight;
        d2 /= totalWeight;
        d3 /= totalWeight;
        d4 /= totalWeight;
        d5 /= totalWeight;
    }
    
    // Blend colors based on influence
    half3 blendedColor = d1 * color1 + d2 * color2 + d3 * color3 + d4 * color4 + d5 * color5;
    
    // Sample the previous frame for motion blur
    half4 lastFrameColor = previousFrame.sample(sampler(coord::normalized), in.texCoord);
    
    // Apply motion blur by mixing with the last frame
    half4 finalColor = half4(mix(lastFrameColor.rgb, blendedColor, 0.85), 1.0); // 85% current frame
    
    return finalColor;
}
