#version 460

#include <common.glsl>
#include <uniforms.glsl>

struct GpuState {
    int particle_count;

    uint _pad0;
    uint _pad1;
    uint _pad2;
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

        vec2 mres = vec2(ubo.frame.monitor_width, ubo.frame.monitor_height);
        int index = atomicAdd(state.particle_count, 1);
        particles[index].pos_x = random() * mres.x;
        particles[index].pos_y = random() * mres.y;
        particles[index].vel_x = 50.0 * (random() - 0.5) * 2.0;
        particles[index].vel_y = 50.0 * (random() - 0.5) * 2.0;
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

#ifdef TICK_PARTICLES_PASS
    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;
        set_seed(id);

        if (id >= state.particle_count) {
            return;
        }

        Particle p = particles[id];

        p.vel_x *= ubo.params.friction;
        p.vel_y *= ubo.params.friction;

        p.pos_x += p.vel_x * ubo.frame.deltatime;
        p.pos_y += p.vel_y * ubo.frame.deltatime;

        if (p.pos_x < 0) {
            p.pos_x = 0;
            p.vel_x *= -1.0;
        }
        if (p.pos_y < 0) {
            p.pos_y = 0;
            p.vel_y *= -1.0;
        }
        if (p.pos_x > ubo.frame.monitor_width) {
            p.pos_x = ubo.frame.monitor_width;
            p.vel_x *= -1.0;
        }
        if (p.pos_y > ubo.frame.monitor_height) {
            p.pos_y = ubo.frame.monitor_height;
            p.vel_y *= -1.0;
        }

        particles[id] = p;
    }
#endif // TICK_PARTICLES_PASS

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

        vec2 pos = vec2(instance.pos_x, instance.pos_y) + ubo.camera.eye.xy;
        pos += vpos * 0.5 * particle_size;
        pos /= mres; // world space to 0..1
        pos *= mres/wres; // 0..1 scaled wrt window size
        pos *= zoom;
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
      float mask = 1.0 - smoothstep(0.45, 0.5, distanceFromCenter);
      // mask = pow(1.0 - distanceFromCenter, 4.5) * mask;
      fcolor = vec4(vec3(0.2, vcolor.y, vcolor.z), vcolor.a * mask * 0.7);
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
        vec2 eye = ubo.camera.eye.xy;
        vec2 mres = vec2(ubo.frame.monitor_width, ubo.frame.monitor_height);
        vec2 wres = vec2(ubo.frame.width, ubo.frame.height);

        vec2 coord = gl_FragCoord.xy;
        coord -= wres / 2.0;
        coord /= zoom;
        coord -= eye;
        coord /= grid_size;

        vec2 rounded = vec2(floor(coord.x), floor(coord.y));
        float checker = mod(floor(rounded.x) + floor(rounded.y), 2.0);

        vec3 color = mix(vec3(0.2, 0.15, 0.35), vec3(0.25, 0.20, 0.40), checker);
        fcolor = vec4(color, 1.0);
    }
#endif // BG_FRAG_PASS
