#version 130
//Interactive Water Surfaces
//Jerry Tessendorf – Rhythm and Hues Studios

uniform sampler2D unit_prev, unit_kern, unit_wave;
uniform vec4 cur_time, wave_con;	//X=alpha, Y=grav

noperspective in vec2 tex_coord;
out float next;
const float level = 0.0;


vec2 delta_kern = vec2(1.0) / textureSize(unit_kern,0);
vec2 delta_wave = vec2(1.0) / textureSize(unit_wave,0);


float sample(const int k, const int l)	{
	vec2 ov = vec2(k+0.5,l+0.5)* delta_kern;
	vec4 off = vec4(k,l,-k,-l) * delta_wave.xyxy;
	float g = texture(unit_kern,ov).x;
	float h = -4.0*level +
		texture(unit_wave, tex_coord + off.xy ).x+
		texture(unit_wave, tex_coord + off.xw ).x+
		texture(unit_wave, tex_coord + off.zy ).x+
		texture(unit_wave, tex_coord + off.zw ).x;
	return g*h;
}

float get_conv1(float wave)	{
	const int P = 6;
	float rez = wave;
	for(int y=1; y<=P; ++y)
		rez += 0.5*(sample(0,y) + sample(y,0));
	for(int x=1; x<=P; ++x)	{
		for(int y=x+1; y<P; ++y)
			rez += sample(x,y) + sample(y,x);
		rez += sample(x,x);
	}
	return rez;
}

float get_conv2(float wave)	{
	const int P = 4;
	float rez = 0.0;
	for(int y=-P; y<=P; ++y)	{
		for(int x=-P; x<=P; ++x)	{
			float g = texture(unit_kern, (abs(vec2(x,y))+vec2(0.5))*delta_kern ).x;
			float h = texture(unit_wave, tex_coord + vec2(x,y)*delta_wave ).x - level;
			rez += g*h;
		}
	}
	return rez;
}

float get_advanced()	{
	float prev = texture(unit_prev, tex_coord).x - level;
	float wave = texture(unit_wave, tex_coord).x - level;
	float conv = get_conv1(wave);

	float dt = min(0.1, cur_time.y),
		alpha = wave_con.x, grav = wave_con.y;
	float cur = wave * (2.0-alpha*dt) - prev - grav*dt*dt*conv;
	return level + cur / (1.0 + alpha * dt);
}

float get_simple()	{
	const float decay = 0.97;
	return level + decay * (0.5*(
		textureOffset(unit_wave, tex_coord, ivec2(1,0)	).x+
		textureOffset(unit_wave, tex_coord, ivec2(-1,0)	).x+
		textureOffset(unit_wave, tex_coord, ivec2(0,1)	).x+
		textureOffset(unit_wave, tex_coord, ivec2(0,-1)	).x
		)-    texture(unit_prev, tex_coord).x - level);
}

float get_simple2()	{
	const float decay = 0.95;
	return level + decay * (
		0.37*(sample(0,1) + sample(1,0)) -
		texture(unit_prev, tex_coord).x + level);
}

void main()	{
	//next = level + texture(unit_kern, tex_coord).x;
	next = get_advanced();
}
