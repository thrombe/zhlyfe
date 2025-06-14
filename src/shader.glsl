#version 460

#include <common.glsl>
#include <uniforms.glsl>

layout(set = 0, binding = _bind_camera) uniform Ubo {
    Uniforms ubo;
};

void set_seed(int id) {
    seed = int(ubo.frame.frame) ^ id ^ floatBitsToInt(ubo.frame.time);
}

#ifdef RENDER_VERT_PASS
    void main() {
    }
#endif // RENDER_VERT_PASS

#ifdef RENDER_FRAG_PASS
    layout(location = 0) out vec4 fcolor;
    void main() {
    }
#endif // RENDER_FRAG_PASS

#ifdef BG_VERT_PASS
    void main() {
        vec3 positions[6] = vec3[6](
            vec3(1.0, 1.0, 0.0),
            vec3(-1.0, 1.0, 0.0),
            vec3(1.0, -1.0, 0.0),
            vec3(1.0, -1.0, 0.0),
            vec3(-1.0, 1.0, 0.0),
            vec3(-1.0, -1.0, 0.0)
        );

        vec3 pos = positions[gl_VertexIndex];

        pos.z = 1.0 - 0.000001;

        gl_Position = vec4(pos, 1.0);
    }
#endif // BG_VERT_PASS

#ifdef BG_FRAG_PASS
    layout(location = 0) out vec4 fcolor;
    void main() {
        float y = gl_FragCoord.y/float(ubo.frame.height) - 0.5;
        // y -= ubo.camera.fwd.y;

        vec3 color = mix(vec3(1.0, 0.6, 0.6), vec3(0.2, 0.2, 0.3), y * 0.5 + 0.5);
        fcolor = vec4(color, 1.0);
    }
#endif // BG_FRAG_PASS
