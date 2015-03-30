# Introduction #

Ant constructor accepts path to the configuration file as it's first parameter. This file usually named _kri.conf_ contains basic project-independent settings.

Comment lines are started with '#' symbol, that can be preceeded only by space characters. These lines are ignored by the parser.

_GL.Context_
Format is "(Y.)X(d)", where Y is a major GL version (default=3), X is a minor version, and 'd' is an optional debugging flag that will potentially provide verbose error reporting from the driver, but with lower performance.

_AL.Device_
String name of the required AL device. Empty string select the default device.

_Window.Title_
Specifies a string value of the window title.

_Window.Size_
Integer value specifies the created window size in formax AxB, where A=width and B=height. Zero value for any component translates the current screen resolution. Both zeroes enable the full-screen mode.

_FB.Samples_
Integer value is the number of samples per pixel in the main framebuffer.

_FB.Buffers_
Integer value is the number of color planes (double-buffering is 2) in the main framebuffer.

_FB.Stereo_
Boolean value (yes/no) is the capability of the main framebuffer to render stereoscopic images.

_FB.Gamma_
Boolean value (yes/no) is the capability of the main framebuffer to perform gamma correction. Also automatically triggers KRI mechanism to render in a gamma-correct way.

_ShaderPath_
String value specifies the path prefix to the engine's shader folder.

_StatPeriod_
Float value specifies the period in seconds at which the statistics will be updated in the window title. A non-positive value turns the statistics off.

_FrameTicks_
Integer value specifies the number of animation updates to do per frame. Zero value - default - use hard-coded separate update rate.