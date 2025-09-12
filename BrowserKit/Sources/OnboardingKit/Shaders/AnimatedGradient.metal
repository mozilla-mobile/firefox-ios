// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex Data Structures
struct VertexOutput {
    float4 position [[position]];
    float2 textureCoordinate;
};

struct GradientControlPoint {
    float2 position;
    half3 color;
    float influence;
};

// MARK: - Gradient Palette Struct
struct GradientPalette {
    float3 gradientOnboardingStop1;
    float3 gradientOnboardingStop2;
    float3 gradientOnboardingStop3;
    float3 gradientOnboardingStop4;
};

// MARK: - Utility Functions
/**
 * Generates a pseudo-random value from a 2D coordinate
 * Uses a hash function for deterministic noise generation
 */
static float generatePseudoRandomValue(float2 coordinate) {
    // Noise generation constants
    const float kNoiseHashX = 127.1f;
    const float kNoiseHashY = 311.7f;
    const float kNoiseMultiplier = 43758.5453f;

    const float2 hashVector = float2(kNoiseHashX, kNoiseHashY);
    return fract(sin(dot(coordinate, hashVector)) * kNoiseMultiplier);
}

/**
 * Generates smooth Perlin-like noise for given coordinates
 * Used for organic movement and texture variation
 */
static float generatePerlinNoise(float2 coordinate) {
    const float2 integerPart = floor(coordinate);
    const float2 fractionalPart = fract(coordinate);

    // Sample noise at four corners of the unit square
    const float topLeftCorner = generatePseudoRandomValue(integerPart);
    const float topRightCorner = generatePseudoRandomValue(integerPart + float2(1.0f, 0.0f));
    const float bottomLeftCorner = generatePseudoRandomValue(integerPart + float2(0.0f, 1.0f));
    const float bottomRightCorner = generatePseudoRandomValue(integerPart + float2(1.0f, 1.0f));

    // Smooth interpolation (Hermite interpolation)
    const float2 smoothInterpolation = fractionalPart * fractionalPart * (3.0f - 2.0f * fractionalPart);

    // Bilinear interpolation
    const float topEdgeInterpolation = mix(topLeftCorner, topRightCorner, smoothInterpolation.x);
    const float bottomEdgeInterpolation = mix(bottomLeftCorner, bottomRightCorner, smoothInterpolation.x);

    return mix(topEdgeInterpolation, bottomEdgeInterpolation, smoothInterpolation.y);
}

/**
 * Calculates animated position for a control point using circular motion
 */
static float2 calculateAnimatedControlPointPosition(float2 basePosition, float currentTime, float animationSpeed) {
    // Control point animation radius
    const float kControlPointAnimationRadius = 0.2f;

    const float2 circularOffset = float2(
        kControlPointAnimationRadius * sin(currentTime * animationSpeed),
        kControlPointAnimationRadius * cos(currentTime * animationSpeed)
    );
    return basePosition + circularOffset;
}

/**
 * Calculates influence weight based on distance with exponential falloff
 */
static float calculateDistanceInfluence(float2 fragmentCoordinate, float2 controlPointPosition, float maxInfluenceDistance) {
    // Smoothing constants
    const float kInfluenceFalloffPower = 2.0f;

    const float distanceToControlPoint = distance(fragmentCoordinate, controlPointPosition);
    const float normalizedDistance = max(1.0f - distanceToControlPoint / maxInfluenceDistance, 0.0f);
    return pow(normalizedDistance, kInfluenceFalloffPower);
}

// MARK: - Vertex Shader
vertex VertexOutput animatedGradientVertex(uint vertexID [[vertex_id]]) {
    // Full-screen quad vertices in normalized device coordinates
    constexpr float2 fullScreenQuadPositions[4] = {
        {-1.0f, -1.0f},  // Bottom-left
        { 1.0f, -1.0f},  // Bottom-right
        {-1.0f,  1.0f},  // Top-left
        { 1.0f,  1.0f}   // Top-right
    };

    constexpr float2 textureCoordinates[4] = {
        {0.0f, 0.0f},  // Bottom-left
        {1.0f, 0.0f},  // Bottom-right
        {0.0f, 1.0f},  // Top-left
        {1.0f, 1.0f}   // Top-right
    };

    VertexOutput vertexOutput;
    vertexOutput.position = float4(fullScreenQuadPositions[vertexID], 0.0f, 1.0f);
    vertexOutput.textureCoordinate = textureCoordinates[vertexID];

    return vertexOutput;
}

// MARK: - Fragment Shader
fragment half4 animatedGradientFragment(VertexOutput fragmentInput [[stage_in]],
                                       constant float &currentTime [[buffer(0)]],
                                       constant GradientPalette &palette [[buffer(1)]],
                                       constant float &speedMultiplier [[buffer(2)]],
                                       texture2d<half> previousFrameTexture [[texture(0)]]) {

    // Base animation speeds (configurable multiplier will be applied)
    const float kBaseFirstPointAnimationSpeed = 0.8f;
    const float kBaseSecondPointAnimationSpeed = 0.6f;
    const float kBaseThirdPointAnimationSpeed = 1.5f;
    const float kBaseFourthPointAnimationSpeed = 1.1f;
    const float kBasePulsationSpeed = 1.2f;

    // Animation constants
    const float kBaseInfluenceRadius = 0.725f;
    const float kPulsationAmplitude = 0.05f;
    const float kNoiseScale = 10.0f;
    const float kNoiseInfluence = 0.1f;

    // Motion blur constants
    const float kCurrentFrameWeight = 0.85f; // 85% current frame, 15% previous

    // Smoothing constants
    const float kMinInfluenceThreshold = 0.001f;

    // Control point animation speeds - now configurable with speed multiplier
    const float kFirstPointAnimationSpeed = kBaseFirstPointAnimationSpeed * speedMultiplier;
    const float kSecondPointAnimationSpeed = kBaseSecondPointAnimationSpeed * speedMultiplier;
    const float kThirdPointAnimationSpeed = kBaseThirdPointAnimationSpeed * speedMultiplier;
    const float kFourthPointAnimationSpeed = kBaseFourthPointAnimationSpeed * speedMultiplier;
    const float kPulsationSpeed = kBasePulsationSpeed * speedMultiplier;

    // Use colors from Swift
    const half3 kGradientOnboardingStop1  = half3(palette.gradientOnboardingStop1);
    const half3 kGradientOnboardingStop2 = half3(palette.gradientOnboardingStop2);
    const half3 kGradientOnboardingStop3   = half3(palette.gradientOnboardingStop3);
    const half3 kGradientOnboardingStop4  = half3(palette.gradientOnboardingStop4);

    // Define base positions for gradient control points
    const float2 firstControlPointBase = float2(0.2f, 0.3f);
    const float2 secondControlPointBase = float2(0.8f, 0.7f);
    const float2 thirdControlPointBase = float2(0.6f, 0.3f);
    const float2 fourthControlPointBase = float2(0.4f, 0.6f);

    // Calculate animated control point positions
    const float2 firstControlPointPosition = calculateAnimatedControlPointPosition(
        firstControlPointBase, currentTime, kFirstPointAnimationSpeed);
    const float2 secondControlPointPosition = calculateAnimatedControlPointPosition(
        secondControlPointBase, currentTime, kSecondPointAnimationSpeed);
    const float2 thirdControlPointPosition = calculateAnimatedControlPointPosition(
        thirdControlPointBase, currentTime, kThirdPointAnimationSpeed);
    const float2 fourthControlPointPosition = calculateAnimatedControlPointPosition(
        fourthControlPointBase, currentTime, kFourthPointAnimationSpeed);

    // Calculate dynamic influence radius with pulsation and noise variation
    const float pulsationEffect = kPulsationAmplitude * sin(currentTime * kPulsationSpeed);
    const float noiseVariation = generatePerlinNoise(fragmentInput.textureCoordinate * kNoiseScale + currentTime) * kNoiseInfluence;
    const float dynamicInfluenceRadius = kBaseInfluenceRadius + pulsationEffect + noiseVariation;

    // Calculate influence weights for each control point
    const float firstPointInfluence = calculateDistanceInfluence(fragmentInput.textureCoordinate, firstControlPointPosition, dynamicInfluenceRadius);
    const float secondPointInfluence = calculateDistanceInfluence(fragmentInput.textureCoordinate, secondControlPointPosition, dynamicInfluenceRadius);
    const float thirdPointInfluence = calculateDistanceInfluence(fragmentInput.textureCoordinate, thirdControlPointPosition, dynamicInfluenceRadius);
    const float fourthPointInfluence = calculateDistanceInfluence(fragmentInput.textureCoordinate, fourthControlPointPosition, dynamicInfluenceRadius);

    // Calculate total influence for normalization
    const float totalInfluence = firstPointInfluence + secondPointInfluence + thirdPointInfluence + fourthPointInfluence;

    half3 blendedGradientColor = half3(0.0f);

    if (totalInfluence > kMinInfluenceThreshold) {
        // Normalize influence weights
        const float normalizedFirstInfluence = firstPointInfluence / totalInfluence;
        const float normalizedSecondInfluence = secondPointInfluence / totalInfluence;
        const float normalizedThirdInfluence = thirdPointInfluence / totalInfluence;
        const float normalizedFourthInfluence = fourthPointInfluence / totalInfluence;

        // Blend colors based on normalized influence weights
        blendedGradientColor = normalizedFirstInfluence * kGradientOnboardingStop1 +
                              normalizedSecondInfluence * kGradientOnboardingStop2 +
                              normalizedThirdInfluence * kGradientOnboardingStop3 +
                              normalizedFourthInfluence * kGradientOnboardingStop4;
    }

    // Sample previous frame for motion blur effect
    constexpr sampler previousFrameSampler(coord::normalized,
                                         address::clamp_to_edge,
                                         filter::linear);
    const half4 previousFrameColor = previousFrameTexture.sample(previousFrameSampler, fragmentInput.textureCoordinate);

    // Apply motion blur by blending current and previous frames
    const half3 finalGradientColor = mix(previousFrameColor.rgb,
                                        blendedGradientColor,
                                        half(kCurrentFrameWeight));

    return half4(finalGradientColor, 1.0f);
}
