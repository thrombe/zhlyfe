 // This file is generated from code. DO NOT EDIT.

 struct Params {
     float _pad;
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

