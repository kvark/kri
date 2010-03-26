#version 130
precision lowp float;

uniform float mat_glossiness;

float get_glossiness()	{
	return mat_glossiness;
}