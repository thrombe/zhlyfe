 // This file is generated from code. DO NOT EDIT.

 struct DrawCall {
     uint index_count;
     uint instance_count;
     uint first_index;
     int vertex_offset;
     uint first_instance;
 };

 struct Particle {
     float pos_x;
     float pos_y;
     uint color;
     uint _pad;
 };

 struct Params {
     uint particle_size;
     uint grid_size;
     float zoom;
     uint spawn_count;
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
 const int _bind_particles = 2;

