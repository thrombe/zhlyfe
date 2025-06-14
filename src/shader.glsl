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
    void main() {
        int instance_index = gl_VertexIndex / 6;
        int vert_index = gl_VertexIndex % 6;

        Particle instance = particles[instance_index];
        vec2 vpos = quad_verts[vert_index].xy;

        float zoom = ubo.params.zoom;
        float particle_size = ubo.params.particle_size;
        vec2 mres = vec2(ubo.frame.monitor_width, ubo.frame.monitor_height);
        vec2 wres = vec2(ubo.frame.width, ubo.frame.height);

        // vpos += 1.0;
        vpos *= 0.5;
        // vpos *= mres.y/mres.x;
        // vpos *= mres / wres;
        // vpos *= size;
        // vpos.x *= wres.y / wres.x;
        // vpos *= mres.y / wres.y;

        // vpos *= 0.04;
        // vpos.y *= mres.y/wres.y;
        // vpos.x *= wres.x/mres.x;

        vec2 pos = vec2(instance.pos_x, instance.pos_y);
        pos += vpos * particle_size;
        // pos *= mres / wres;
        // pos -= mres / 2.0;
        // pos /= mres / 2.0;
        pos /= mres;
        pos *= mres/wres;
        // pos += 0.5;
        // pos *= mres.x / wres.x;
        // pos *= mres.y/mres.x;
        pos -= 0.5;
        pos *= 2.0;
        pos *= zoom;
        gl_Position = vec4(pos, 0.0, 1.0);
    }
#endif // RENDER_VERT_PASS

#ifdef RENDER_FRAG_PASS
    layout(location = 0) out vec4 fcolor;
    void main() {
        fcolor = vec4(1.0);
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
      float y = gl_FragCoord.y / grid_size;
      float x = gl_FragCoord.x / grid_size;

      vec2 squareCoord = vec2(floor(x), floor(y)) * zoom;
      float checker = mod(floor(squareCoord.x) + floor(squareCoord.y), 2.0);

      vec3 color = mix(vec3(0.2, 0.15, 0.35), vec3(0.25, 0.20, 0.40), checker);
      // color = vec3(float(state.particle_count) / 500.0);
      // color = vec3(draw_call.index_count > 0);
      // color = vec3(ubo.params.spawn_count == 0);
      // color = vec3(mod(ubo.frame.time, 1.0));
      // color = color * 0.3;
      fcolor = vec4(color, 1.0);
    }
#endif // BG_FRAG_PASS
