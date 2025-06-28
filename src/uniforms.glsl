 // This file is generated from code. DO NOT EDIT.

 struct DrawCall {
     uint index_count;
     uint instance_count;
     uint first_index;
     int vertex_offset;
     uint first_instance;
 };

 struct ParticleType {
     vec4 color;
     float visual_radius;
     uint _pad0;
     uint _pad1;
     uint _pad2;
 };

 struct ParticleForce {
     float attraction_strength;
     float attraction_radius;
     float collision_strength;
     float collision_radius;
 };

 struct Particle {
     vec3 pos;
     vec3 vel;
     uint type_index;
     uint _pad0;
     uint _pad1;
     uint _pad2;
 };

 struct Params {
     float delta;
     uint particle_size;
     uint grid_size;
     float zoom;
     float particle_z_shrinking_factor;
     float friction;
     uint randomize;
     uint particle_type_count;
     uint particle_count;
     uint spawn_count;
     int bin_size;
     int bin_buf_size;
     int bin_buf_size_x;
     int bin_buf_size_y;
     int bin_buf_size_z;
     int world_size_x;
     int world_size_y;
     int world_size_z;
     uint _pad0;
     uint _pad1;
 };

 struct PushConstants {
     int reduce_step;
     uint _pad0;
     uint _pad1;
     uint _pad2;
 };

 struct Camera2DMeta {
     uint did_move;
     uint _pad1;
     uint _pad2;
     uint _pad3;
 };

 struct Camera2D {
     vec4 eye;
     Camera2DMeta meta;
 };

 struct Frame {
     uint frame;
     float time;
     float deltatime;
     int width;
     int height;
     int monitor_width;
     int monitor_height;
     uint pad0;
 };

 struct Mouse {
     int x;
     int y;
     uint left;
     uint right;
 };

 struct Uniforms {
     Camera2D camera;
     Frame frame;
     Mouse mouse;
     Params params;
 };

 const int _bind_camera = 0;
 const int _bind_particles_draw_call = 1;
 const int _bind_scratch = 2;
 const int _bind_particle_types = 3;
 const int _bind_particle_force_matrix = 4;
 const int _bind_particles_back = 5;
 const int _bind_particles = 6;
 const int _bind_particle_bins_back = 7;
 const int _bind_particle_bins = 8;

