#version 460

#include <common.glsl>
#include <uniforms.glsl>

struct GpuState {
    int particle_count;

    vec4 _pad_aligned;
};

vec3 quad_verts[6] = vec3[6](
    vec3(1.0, 1.0, 0.0),
    vec3(-1.0, 1.0, 0.0),
    vec3(1.0, -1.0, 0.0),
    vec3(1.0, -1.0, 0.0),
    vec3(-1.0, 1.0, 0.0),
    vec3(-1.0, -1.0, 0.0)
);
vec2 quad_uvs[6] = vec2[6](
    vec2(1.0, 1.0),
    vec2(0.0, 1.0),
    vec2(1.0, 0.0),
    vec2(1.0, 0.0),
    vec2(0.0, 1.0),
    vec2(0.0, 0.0)
);

#ifdef COMPUTE_PASS
    #define bufffer buffer
#else
    #define bufffer readonly buffer
#endif

layout(set = 0, binding = _bind_camera) uniform Ubo {
    Uniforms ubo;
};
layout(set = 0, binding = _bind_particles) bufffer ParticleBuffer {
    // uhohh. steal some memory from particle buffer
    GpuState state;
    Particle particles[];
};
layout(set = 0, binding = _bind_particles_draw_call) bufffer ParticlesDrawCallBuffer {
    DrawCall draw_call;
};

void set_seed(int id) {
    seed = int(ubo.frame.frame) ^ id ^ floatBitsToInt(ubo.frame.time);
}

#ifdef SPAWN_PARTICLES_PASS
    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;
        set_seed(id);

        if (id >= ubo.params.spawn_count) {
            return;
        }

        if (id == 0 && ubo.frame.frame == 1) {
            atomicExchange(state.particle_count, -1);
        }

        memoryBarrierBuffer();

        vec2 mres = vec2(ubo.frame.monitor_width, ubo.frame.monitor_height);
        int index = atomicAdd(state.particle_count, 1);
        particles[index].pos_x = random() * mres.x;
        particles[index].pos_y = random() * mres.y;
        particles[index].color = rgba_encode_u32(vec4(random(), random(), random(), 1.0));

        if (id > 0) {
            return;
        }

        memoryBarrierBuffer();

        int count = atomicAdd(state.particle_count, 0);
        draw_call.index_count = count * 6;
        draw_call.instance_count = 1;
        draw_call.first_index = 0;
        draw_call.vertex_offset = 0;
        draw_call.first_instance = 0;
    }
#endif // SPAWN_PARTICLES_PASS

#ifdef RENDER_VERT_PASS
    layout(location = 0) out vec4 vcolor;
    layout(location = 1) out vec2 vuv;
    void main() {
        int instance_index = gl_VertexIndex / 6;
        int vert_index = gl_VertexIndex % 6;

        Particle instance = particles[instance_index];
        vec2 vpos = quad_verts[vert_index].xy;

        float zoom = ubo.params.zoom;
        float particle_size = ubo.params.particle_size;
        vec2 mres = vec2(ubo.frame.monitor_width, ubo.frame.monitor_height);
        vec2 wres = vec2(ubo.frame.width, ubo.frame.height);

        vec2 pos = vec2(instance.pos_x, instance.pos_y);
        pos += vpos * 0.5 * particle_size;
        pos /= mres; // world space to 0..1
        pos *= mres/wres; // 0..1 scaled wrt window size
        pos *= zoom;
        pos -= 0.5;
        pos *= 2.0;
        gl_Position = vec4(pos, 0.0, 1.0);

        vcolor = rgba_decode_u32(instance.color);
        vuv = quad_uvs[vert_index];
    }
#endif // RENDER_VERT_PASS

#ifdef RENDER_FRAG_PASS
    layout(location = 0) in vec4 vcolor;
    layout(location = 1) in vec2 vuv;
    layout(location = 0) out vec4 fcolor;
    void main() {
      float distanceFromCenter = length(vuv.xy - 0.5);
      float mask = 0.5 - smoothstep(0.5, 0.45, distanceFromCenter);
      fcolor = vec4(vec3(mask), vcolor.a * mask);
    }
#endif // RENDER_FRAG_PASS

#ifdef BG_VERT_PASS
    void main() {
        vec3 pos = quad_verts[gl_VertexIndex];

        pos.z = 1.0 - 0.000001;

        gl_Position = vec4(pos, 1.0);
    }
#endif // BG_VERT_PASS

#ifdef BG_FRAG_PASS
    layout(location = 0) out vec4 fcolor;
    void main() {
        float grid_size = ubo.params.grid_size;
        float zoom = ubo.params.zoom;
        vec2 resolution = vec2(ubo.frame.monitor_width, ubo.frame.monitor_height);
        float centerX = resolution.x / 2.0;
        float centerY = resolution.y / 2.0;

        float y = (gl_FragCoord.y - centerY) / (grid_size * zoom) + centerY / (grid_size * zoom);
        float x = (gl_FragCoord.x - centerX) / (grid_size * zoom) + centerX / (grid_size * zoom);

        vec2 squareCoord = vec2(floor(x), floor(y));
        float checker = mod(floor(squareCoord.x) + floor(squareCoord.y), 2.0);

        vec3 color = mix(vec3(0.2, 0.15, 0.35), vec3(0.25, 0.20, 0.40), checker);
        fcolor = vec4(color, 1.0);
    }
#endif // BG_FRAG_PASS
