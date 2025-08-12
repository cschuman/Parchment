#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

struct Uniforms {
    float4x4 projectionMatrix;
    float4 textColor;
};

vertex VertexOut optimizedTextVertex(VertexIn in [[stage_in]],
                                     constant Uniforms& uniforms [[buffer(0)]]) {
    VertexOut out;
    out.position = uniforms.projectionMatrix * float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    out.color = uniforms.textColor;
    return out;
}

fragment float4 optimizedTextFragment(VertexOut in [[stage_in]],
                                      texture2d<float> glyphTexture [[texture(0)]],
                                      sampler glyphSampler [[sampler(0)]]) {
    float alpha = glyphTexture.sample(glyphSampler, in.texCoord).r;
    
    // Subpixel antialiasing
    float3 subpixel = glyphTexture.sample(glyphSampler, in.texCoord).rgb;
    
    // Gamma correction for better text rendering
    alpha = pow(alpha, 1.0/2.2);
    
    // Apply text color with alpha
    return float4(in.color.rgb, in.color.a * alpha);
}

// Optimized shader for distance field text rendering
fragment float4 distanceFieldTextFragment(VertexOut in [[stage_in]],
                                         texture2d<float> sdfTexture [[texture(0)]],
                                         sampler sdfSampler [[sampler(0)]],
                                         constant float& smoothing [[buffer(0)]]) {
    float distance = sdfTexture.sample(sdfSampler, in.texCoord).r;
    
    // Calculate alpha with smooth edges
    float alpha = smoothstep(0.5 - smoothing, 0.5 + smoothing, distance);
    
    // Enhanced edge quality
    float2 dxdy = fwidth(in.texCoord);
    float gradientLength = length(dxdy);
    alpha = smoothstep(0.5 - gradientLength, 0.5 + gradientLength, distance);
    
    return float4(in.color.rgb, in.color.a * alpha);
}

// Blur shader for placeholder images
kernel void gaussianBlur(texture2d<float, access::read> input [[texture(0)]],
                         texture2d<float, access::write> output [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    
    float4 color = float4(0.0);
    float kernel[9] = {
        0.0625, 0.125, 0.0625,
        0.125,  0.25,  0.125,
        0.0625, 0.125, 0.0625
    };
    
    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            uint2 coord = uint2(int2(gid) + int2(i, j));
            coord = clamp(coord, uint2(0), uint2(input.get_width() - 1, input.get_height() - 1));
            color += input.read(coord) * kernel[(j + 1) * 3 + (i + 1)];
        }
    }
    
    output.write(color, gid);
}