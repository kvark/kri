#version 150 core

uniform sampler1D unit_kern;
uniform sampler2D unit_wave;
uniform vec4 cur_time, wave_con;	//X=alpha, Y=grav

noperspective in vec2 tex_coord;
out vec2 next;
const vec2 level = vec2(0.0);

float delta_kern = 1.0 / textureSize(unit_kern,0);
vec2 delta_wave = vec2(1.0) / textureSize(unit_wave,0);


//----------------------//
//	FUTURISTIC	//

//X=height, Y=momentum

float sample2(int x, int y, float kf)	{
	vec2 r = vec2(x,y);
	float ov = (dot(r,r)+0.5) * delta_kern;
	vec2 tc	= tex_coord + r*delta_wave;
	float g	= texture(unit_kern,ov).x;
	vec2 w	= texture(unit_wave,tc).xy - level;
	return g * (w.y + kf*w.x);
} 

vec2 get_future()	{
	const int P = 1;
	//get source
	vec2 wave = texture(unit_wave, tex_coord).xy - level;
	float dt = cur_time.x;
	float kf = -0.5*dt * wave_con.y;
	//get convoluted phi
	float dphi = 0.0;
	for(int x=-P; x<=P; ++x)	{
		for(int y=-P; y<=P; ++y)	{
			dphi += sample2(x,y,kf);
		}
	}
	//get result
	float h2 = wave.x + dt*dphi;
	return level + vec2(h2, wave.y + kf*(wave.x+h2));
}


//----------------------//
//	ADVANCED	//

//Interactive Water Surfaces
//Jerry Tessendorf – Rhythm and Hues Studios
//X=current, Y=prev

float sample(const int k, const int l)	{
	float ov = (k*k+l*l+0.5) * delta_kern;
	vec4 off = vec4(k,l,-k,-l) * delta_wave.xyxy;
	float g = texture(unit_kern,ov).x;
	float h = -4.0*level.x +
		texture(unit_wave, tex_coord + off.xy ).x+
		texture(unit_wave, tex_coord + off.xw ).x+
		texture(unit_wave, tex_coord + off.zy ).x+
		texture(unit_wave, tex_coord + off.zw ).x;
	return g*h;
}

float get_conv1()	{
	const int P = 6;
	float rez = 0.0;
	for(int y=1; y<=P; ++y)
		rez += 0.5*(sample(0,y) + sample(y,0));
	for(int x=1; x<=P; ++x)	{
		for(int y=x+1; y<P; ++y)
			rez += sample(x,y) + sample(y,x);
		rez += sample(x,x);
	}
	return rez;
}

float get_conv2()	{
	const int P = 4;
	float rez = 0.0;
	for(int y=-P; y<=P; ++y)	{
		for(int x=-P; x<=P; ++x)	{
			float g = texture(unit_kern, (x*x+y*y+0.5)*delta_kern ).x;
			float h = texture(unit_wave, tex_coord + vec2(x,y)*delta_wave ).x - level.x;
			rez += g*h;
		}
	}
	return rez;
}

vec2 get_advanced()	{
	vec2 wave = texture(unit_wave, tex_coord).xy - level;
	float conv = wave.x + get_conv1();	//get_conv2();
	float dt = min(0.1, cur_time.x),
		alpha = wave_con.x, grav = wave_con.y;
	float cur = wave.x * (2.0-alpha*dt) - wave.y - grav*dt*dt*conv;
	return level + vec2(cur / (1.0 + alpha * dt), wave.x);
}


//----------------------//
//	SIMPLE		//

//Unknow source
//X=current, Y=prev

vec2 get_simple()	{
	const float decay = 0.97;
	vec2 wave = texture(unit_wave, tex_coord).xy - level;
	const ivec3 io = ivec3(-1,0,1);
	float val = 0.5*(
		textureOffset(unit_wave, tex_coord, io.zy).x+
		textureOffset(unit_wave, tex_coord, io.xy).x+
		textureOffset(unit_wave, tex_coord, io.yz).x+
		textureOffset(unit_wave, tex_coord, io.yx).x
		)-2.0*level.x - wave.y;
	return level + vec2(decay*val,wave.x);
}

//----------------------//
//	MAIN		//

void main()	{
	//next = level + texture(unit_kern, tex_coord).x;
	next = get_future();
}
