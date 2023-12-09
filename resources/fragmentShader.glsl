/*
	fragmentShader.glsl
	author: Telo PHILIPPE

	Use shell texturing to create a grass effect
*/

#version 460 core

#define FLT_MAX 3.402823466e+38

const vec3 clearColor = vec3(0.1f, 0.1f, 0.1f);

out vec4 outColor;

in vec2 screenPos;

uniform mat4 u_viewMat;
uniform mat4 u_projMat;
uniform mat4 u_invViewMat;
uniform mat4 u_invProjMat;

uniform vec3 u_cameraPosition;

uniform float u_time;

vec3 lightDir = normalize(vec3(1, 2, 1));

struct Ray {
	vec3 origin;
	vec3 direction;

	float t;
	
	float absorption;
};

uniform sampler3D u_volumeTex;

void swap(inout float a, inout float b) {
	float tmp = a;
	a = b;
	b = tmp;
}

bool projectToCube(vec3 ro, vec3 rd, out float tmin, out float tmax) {
	
	tmin = (-1.0f - ro.x) / rd.x;
	tmax = (+1.0f - ro.x) / rd.x;
	if (tmin > tmax) swap(tmin, tmax);

	float tymin = (-1.0f - ro.y) / rd.y;
	float tymax = (+1.0f - ro.y) / rd.y;
	if (tymin > tymax) swap(tymin, tymax);
	if ((tmin > tymax) || (tymin > tmax)) 
        return false; 
	if (tymin > tmin)
		tmin = tymin;
	if (tymax < tmax)
		tmax = tymax;

	float tzmin = (-1.0f - ro.z) / rd.z;
	float tzmax = (+1.0f - ro.z) / rd.z;
	if (tzmin > tzmax) swap(tzmin, tzmax);

	if ((tmin > tzmax) || (tzmin > tmax)) 
		return false;
	if (tzmin > tmin)
		tmin = tzmin;
	if (tzmax < tmax)
		tmax = tzmax;
	
	return true;
}

vec3 mix(vec3 a, vec3 b, vec3 t) {
	return a * (1.0f - t) + b * t;
}

void main() {
	vec2 uv = screenPos;// * 2.0f - 1.0f;

	vec4 clip = vec4(uv, -1.0, 1.0);
	vec4 eye = vec4(vec2(u_invProjMat * clip), -1.0, 0.0);
	vec3 rayDir = vec3(u_invViewMat * eye);
	vec3 rayOrigin = u_invViewMat[3].xyz;

	Ray ray = Ray(rayOrigin, rayDir, 0.0f, 1.0f);

	float stepSize = 0.01f;

	float tmin, tmax;

	bool intersects = projectToCube(ray.origin, ray.direction, tmin, tmax);
	if(!intersects) discard;

	vec3 absorption = vec3(1.0f);

	for (float t = tmin; t < tmax; t += stepSize) {
		vec3 p = ray.origin + ray.direction * t;
		vec3 s = texture(u_volumeTex, p * 0.5 + 0.5).xyz;
		absorption *= pow(1-s, vec3(0.05f));
	}
	

	ray.absorption = pow(0.5f, ray.t - tmin);

	vec3 finalColor = vec3(1.0f);
	vec3 finalAlpha = absorption;

	outColor = vec4(mix(finalColor, clearColor, finalAlpha), 1.0f);
}