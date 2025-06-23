#version 460

#include <common.glsl>
#include <uniforms.glsl>

struct GpuState {
    int particle_count;
    int prefix_sum_pass;

    int bad_flag;

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
layout(set = 0, binding = _bind_scratch) bufffer ScratchBuffer {
    GpuState state;
};
layout(set = 0, binding = _bind_particles_back) bufffer ParticleBackBuffer {
    Particle particles_back[];
};
layout(set = 0, binding = _bind_particles) bufffer ParticleBuffer {
    Particle particles[];
};
layout(set = 0, binding = _bind_particle_bins_back) bufffer ParticleBinBackBuffer {
    int particle_bins_back[];
};
layout(set = 0, binding = _bind_particle_bins) bufffer ParticleBinBuffer {
    int particle_bins[];
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
        Particle p;
        p.pos = vec2(random(), random()) * mres;
        p.vel = 50.0 * (vec2(random(), random()) - 0.5) * 2.0;
        p.color = rgba_encode_u32(vec4(random(), random(), random(), 1.0));
        particles[index] = p;

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

#ifdef BIN_RESET_PASS
    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;

        // particle_bins[id] = 0;
        // particle_bins_back[id] = 0;
        // int index = int(ubo.frame.time) % ubo.params.bin_buf_size;
        // atomicExchange(particle_bins_back[index], 1);
        if (ubo.frame.frame % 2 == 0) {
            // atomicAdd(particle_bins_back[index], -1);
        } else {
            // atomicAdd(particle_bins_back[index], 1);
            // atomicAdd(particle_bins[index], -1);
        }

        if (id >= ubo.params.bin_buf_size) {
            return;
        }

        particle_bins[id] = 0;
        particle_bins_back[id] = 0;

        if (id == 0) {
            state.prefix_sum_pass = 0;
            state.bad_flag = 0;
        }
    }
#endif // BIN_RESET_PASS

#ifdef PARTICLE_COUNT_PASS
    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;

        if (id >= state.particle_count) {
            return;
        }

        Particle p = particles[id];

        ivec2 pos = ivec2(p.pos / ubo.params.bin_size);
        pos = clamp(pos, ivec2(0, 0), ivec2(ubo.params.bin_buf_size_x - 1, ubo.params.bin_buf_size_y - 1));
        int index = clamp(pos.y * ubo.params.bin_buf_size_x + pos.x, 0, ubo.params.bin_buf_size);

        int _count = atomicAdd(particle_bins_back[index], 1);
    }
#endif // PARTICLE_COUNT_PASS

#ifdef BIN_PREFIX_SUM_PASS
    layout(push_constant) uniform PushConstantsUniform {
        PushConstants push;
    };

    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;

        // particle_bins[id] = particle_bins_back[id];
        // return;
        if (id >= ubo.params.bin_buf_size) {
            return;
        }

        int step = 1 << push.reduce_step;
        if (id >= step) {
            int a = particle_bins_back[id];
            int b = particle_bins_back[id - step];
            particle_bins[id] = a + b;
        } else {
            int a = particle_bins_back[id];
            particle_bins[id] = a;
        }

        // particle_bins[step] = 1;
        // particle_bins_back[step] = 1;

        // for (int i=1; i<=1; i<<=1) {
        //     int step = i << state.prefix_sum_pass;
        //     // particle_bins[step] = 100000;
        //     if (id >= step) {
        //         int a = particle_bins_back[id];
        //         int b = particle_bins_back[id - step];
        //         particle_bins[id] = a + b;
        //     }
        // }
    }
#endif // BIN_PREFIX_SUM_PASS

#ifdef PARTICLE_BINNING_PASS
    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;

        // Particle pp = particles[id];
        // particles_back[id] = pp;
        // return;

        if (id >= state.particle_count) {
            return;
        }

        Particle p = particles[id];

        ivec2 pos = ivec2(p.pos / ubo.params.bin_size);
        pos = clamp(pos, ivec2(0, 0), ivec2(ubo.params.bin_buf_size_x - 1, ubo.params.bin_buf_size_y - 1));
        int index = clamp(pos.y * ubo.params.bin_buf_size_x + pos.x, 0, ubo.params.bin_buf_size);

        int bin_index = atomicAdd(particle_bins[index], -1);

        if (bin_index > 0) {
            state.bad_flag = 1;
        }

        // p.color = rgba_encode_u32(vec4(index == ubo.params.bin_buf_size - 1, 0.0, 0.0, 1.0));
        particles_back[bin_index - 1] = p;
    }
#endif // PARTICLE_BINNING_PASS

#ifdef TICK_PARTICLES_PASS
    layout (local_size_x = 8, local_size_y = 8) in;
    void main() {
        int id = global_id;
        set_seed(id);

        // Particle pp = particles_back[id];
        // particles[id] = pp;
        // return;

        if (id >= state.particle_count) {
            return;
        }

        Particle p = particles_back[id];

        p.vel *= ubo.params.friction;
        p.pos += p.vel * ubo.frame.deltatime;

        if (p.pos.x < 0) {
            p.pos.x = float(ubo.frame.monitor_width);
        }
        if (p.pos.y < 0) {
            p.pos.y = float(ubo.frame.monitor_height);
        }
        if (p.pos.x > ubo.frame.monitor_width) {
            p.pos.x = 0;
        }
        if (p.pos.y > ubo.frame.monitor_height) {
            p.pos.y = 0;
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

        vec2 pos = instance.pos + ubo.camera.eye.xy;
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
        float zoom = ubo.params.zoom;
        float distanceFromCenter = length(vuv.xy - 0.5);
        float mask = 1.0 - smoothstep(0.5 - 0.1/zoom, 0.5, distanceFromCenter);
        // mask = pow(1.0 - distanceFromCenter, 4.5) * mask;
        mask = 1.0;
        fcolor = vec4(vec3(vcolor.x, vcolor.y, vcolor.z), 1.0);
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

        vec2 fpos = gl_FragCoord.xy;
        fpos -= wres / 2.0;
        fpos /= zoom;
        fpos -= eye;
        fpos /= grid_size;
        ivec2 pos = ivec2(int(fpos.x), int(fpos.y));
        pos.y += 3;
        int index = pos.y * ubo.frame.width + pos.x;
        if (ubo.params.bin_buf_size > index && index >= 0) {
            int count = particle_bins[index];
            // color = vec3(float(count) > 3000);
            // color = vec3(sqrt(float(count))/50.0);
            color = vec3(float(count)/4500.0);
            // color = vec3(float(count)/1600.0);
            // color = vec3(float(count)/700.0);
            // color = vec3(float(count)/300.0);
            // color = vec3(float(count)/50.0);

            color = vec3(float(particle_bins[index] > 4500 * mod(ubo.frame.time, 1)));
            // color = vec3(float(particle_bins[index] > 20 * mod(ubo.frame.time, 1)));
        }

        // if (state.bad_flag > 0) {
        //     color = vec3(1, 0, 0);
        // }
        
        fcolor = vec4(color, 1.0);
    }
#endif // BG_FRAG_PASS
