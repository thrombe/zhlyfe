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
      float zoom = 32.0;
      float y = gl_FragCoord.y / zoom - 0.5 * zoom;
      float x = gl_FragCoord.x / zoom - 0.5 * zoom;

      vec2 squareCoord = vec2(floor(x), floor(y));
      float checker = mod(floor(squareCoord.x) + floor(squareCoord.y), 2.0);

      vec3 color = mix(vec3(0.2, 0.15, 0.35), vec3(0.25, 0.20, 0.40), checker);
      fcolor = vec4(color, 1.0);
    }
#endif // BG_FRAG_PASS
