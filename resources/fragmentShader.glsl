/*
	fragmentShader.glsl
	author: Telo PHILIPPE

	Use shell texturing to create a grass effect
*/

#version 460 core

#define FLT_MAX 3.402823466e+38

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

/*float projectToCube(vec3 ro, vec3 rd) {
	
	float tx1 = (0 - ro.x) / rd.x;
	float tx2 = (map.size.x - ro.x) / rd.x;

	float ty1 = (0 - ro.y) / rd.y;
	float ty2 = (map.size.y - ro.y) / rd.y;

	float tz1 = (0 - ro.z) / rd.z;
	float tz2 = (map.size.z - ro.z) / rd.z;

	float tx = max(min(tx1, tx2), 0);
	float ty = max(min(ty1, ty2), 0);
	float tz = max(min(tz1, tz2), 0);

	float t = max(tx, max(ty, tz));
	
	return t;
}*/

void main() {
	vec2 uv = screenPos;// * 2.0f - 1.0f;

	vec4 clip = vec4(uv, -1.0, 1.0);
	vec4 eye = vec4(vec2(u_invProjMat * clip), -1.0, 0.0);
	vec3 rayDir = vec3(u_invViewMat * eye);
	vec3 rayOrigin = u_invViewMat[3].xyz;

	Ray ray = Ray(rayOrigin, rayDir, 0.0f, 1.0f);

	int numSteps = 100;
	float stepSize = 0.01f;

	for(int i=0; i<numSteps; i++) {
		vec3 position = ray.origin + ray.direction * ray.t;
		vec3 color = texture(u_volumeTex, position).rgb;

		ray.absorption *= pow(0.99f, 1.0f - color.r);

		ray.t += stepSize;
	}


	vec3 finalColor = mix(rayDir, vec3(1.0f), ray.absorption);

	outColor = vec4(finalColor, 1.0f);
}