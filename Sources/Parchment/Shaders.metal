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
    float fontSize;
    float smoothing;
};

vertex VertexOut textVertexShader(
    VertexIn in [[stage_in]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    VertexOut out;
    out.position = uniforms.projectionMatrix * float4(in.position, 0.0, 1.0);
    out.texCoord = in.texCoord;
    out.color = uniforms.textColor;
    return out;
}

fragment float4 textFragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> glyphTexture [[texture(0)]],
    sampler glyphSampler [[sampler(0)]],
    constant Uniforms& uniforms [[buffer(0)]]
) {
    float distance = glyphTexture.sample(glyphSampler, in.texCoord).r;
    
    float width = uniforms.smoothing;
    float alpha = smoothstep(0.5 - width, 0.5 + width, distance);
    
    if (alpha < 0.01) {
        discard_fragment();
    }
    
    return float4(in.color.rgb, in.color.a * alpha);
}

kernel void blurKernel(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    
    float4 color = float4(0.0);
    float weight = 0.0;
    
    const int radius = 3;
    for (int x = -radius; x <= radius; x++) {
        for (int y = -radius; y <= radius; y++) {
            uint2 coord = uint2(gid.x + x, gid.y + y);
            
            if (coord.x < input.get_width() && coord.y < input.get_height()) {
                float w = exp(-float(x*x + y*y) / (2.0 * radius * radius));
                color += input.read(coord) * w;
                weight += w;
            }
        }
    }
    
    output.write(color / weight, gid);
}

struct GlyphVertex {
    float2 position;
    float2 texCoord;
    float4 color;
};

vertex VertexOut glyphVertexShader(
    uint vertexID [[vertex_id]],
    constant GlyphVertex* vertices [[buffer(0)]],
    constant Uniforms& uniforms [[buffer(1)]]
) {
    GlyphVertex vertex = vertices[vertexID];
    
    VertexOut out;
    out.position = uniforms.projectionMatrix * float4(vertex.position, 0.0, 1.0);
    out.texCoord = vertex.texCoord;
    out.color = vertex.color;
    
    return out;
}

fragment float4 glyphFragmentShader(
    VertexOut in [[stage_in]],
    texture2d<float> atlas [[texture(0)]],
    sampler atlasSampler [[sampler(0)]]
) {
    float alpha = atlas.sample(atlasSampler, in.texCoord).a;
    return float4(in.color.rgb, in.color.a * alpha);
}

kernel void compositeKernel(
    texture2d<float, access::read> textLayer [[texture(0)]],
    texture2d<float, access::read> backgroundLayer [[texture(1)]],
    texture2d<float, access::write> output [[texture(2)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
        return;
    }
    
    float4 text = textLayer.read(gid);
    float4 background = backgroundLayer.read(gid);
    
    float4 result = mix(background, text, text.a);
    output.write(result, gid);
}