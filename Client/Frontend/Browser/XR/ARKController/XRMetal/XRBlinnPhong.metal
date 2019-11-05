
#include <metal_stdlib>
using namespace metal;

struct FrameUniforms {
    float4x4 viewMatrix;
    float4x4 viewProjectionMatrix;
};

struct InstanceUniforms {
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

constant int AttributeIndexPosition = 0;
constant int AttributeIndexNormal = 1;
//constant int AttributeIndexColor = 2;
constant int AttributeIndexTexCoords = 3;

constant int BufferIndexInstanceUniforms = 8;
constant int BufferIndexFrameUniforms = 9;

constant int TextureIndexDiffuse = 0;
constant int TextureIndexNormal = 1;
constant int TextureIndexEmissive = 2;
//constant int TextureIndexMetalness = 3;
//constant int TextureIndexRoughness = 4;
//constant int TextureIndexOcclusion = 5;

struct VertexIn {
    float3 position  [[attribute(AttributeIndexPosition)]];
    float3 normal    [[attribute(AttributeIndexNormal)]];
    float2 texCoords [[attribute(AttributeIndexTexCoords)]];
};

struct VertexOut {
    float4 positionClip [[position]];
    float3 eyePosition;
    float3 eyeNormal;
    float2 texCoords;
};

vertex VertexOut blinnPhongVertex(VertexIn in [[stage_in]],
                                  constant InstanceUniforms &instance [[buffer(BufferIndexInstanceUniforms)]],
                                  constant FrameUniforms &frame [[buffer(BufferIndexFrameUniforms)]])
{
    VertexOut out;
    float4 modelPosition = float4(in.position, 1);
    out.positionClip = frame.viewProjectionMatrix * instance.modelMatrix * modelPosition;
    out.eyePosition = (frame.viewMatrix * instance.modelMatrix * modelPosition).xyz;
    out.eyeNormal = instance.normalMatrix * in.normal;
    out.texCoords = in.texCoords;
    return out;
}

typedef VertexOut FragmentIn;

fragment half4 blinnPhongFragment(FragmentIn in [[stage_in]],
                                  texture2d<float, access::sample> diffuseTexture [[texture(TextureIndexDiffuse)]],
                                  texture2d<float, access::sample> normalTexture [[texture(TextureIndexNormal)]],
                                  texture2d<float, access::sample> emissiveTexture [[texture(TextureIndexEmissive)]]/*,
                                  texture2d<float, access::sample> metalnessTexture [[texture(TextureIndexMetalness)]],
                                  texture2d<float, access::sample> roughnessTexture [[texture(TextureIndexRoughness)]],
                                  texture2d<float, access::sample> occlusionTexture [[texture(TextureIndexOcclusion)]]*/)
{
    constexpr sampler linearSampler(filter::linear);
    
    float3 eyeLightPosition(1, 1, 1);
    
    float ambient = 0.1;
    
    float3 L = normalize(eyeLightPosition - in.eyePosition);
    float3 N = normalize(in.eyeNormal);

    float diffuse = saturate(dot(N, L));
    
    float3 V = -normalize(in.eyePosition);
    float3 H = normalize(V + L);

    float specular = pow(saturate(dot(N, H)), 64);

    float4 baseColor = diffuseTexture.sample(linearSampler, in.texCoords);
    float3 diffuseColor = baseColor.rgb;
    
    float3 color = (ambient + diffuse) * diffuseColor + specular;

    return half4(half3(color), 1);
}
