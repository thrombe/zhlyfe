 // This file is generated from code. DO NOT EDIT.

 struct DrawCall {
     uint index_count;
     uint instance_count;
     uint first_index;
     int vertex_offset;
     uint first_instance;
 };

 struct Particle {
     vec2 pos;
     vec2 vel;
     uint color;
     uint _pad0;
     uint _pad1;
     uint _pad2;
 };

 struct Params {
     uint particle_size;
     uint grid_size;
     float zoom;
     float friction;
     uint particle_count;
     uint spawn_count;
     int bin_size;
     int bin_buf_size;
     int bin_buf_size_x;
     int bin_buf_size_y;
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
 const int _bind_particles_back = 3;
 const int _bind_particles = 4;
 const int _bind_particle_bins_back = 5;
 const int _bind_particle_bins = 6;

