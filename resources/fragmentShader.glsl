/*
	fragmentShader.glsl
	author: Telo PHILIPPE

	Use shell texturing to create a grass effect
*/

#version 460 core

#define FLT_MAX 3.402823466e+38
#define PI 3.1415926535897932384626433832795

const vec3 clearColor = vec3(0.2f, 0.7f, 0.95f);

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
	
	tmin = max(tmin, 0.0f);
	tmax = max(tmax, 0.0f);
	if(tmin >= tmax) return false;

	return true;
}

vec3 mix3(vec3 a, vec3 b, vec3 t) {
	return a * (1.0f - t) + b * t;
}

float mExp(float x, float sigma) { // Beer's powder function
	//x = min(max(x, 0.0f), 10.0f);
	return exp(-x * sigma);// * (1.0 - exp(-2*x*sigma));
}

float Henyey_Greenstein(float cosTheta, float g) {
	float denom = 1.0f + g * g + 2.0f * g * cosTheta;
	return (1.0f - g * g) / (denom * sqrt(denom) * 4.0f * PI);
}


uniform vec3 u_lightPosition;
uniform vec3 u_lightColor;

uniform float u_densityFactor;

uniform float u_stepSize;
uniform float u_lightStepSize;

uniform int u_numSteps;
uniform int u_numLightSteps;

uniform float u_absorptionFactor;
uniform float u_lightAbsorptionFactor;

float sampleDensity(vec3 p) {
	return pow(texture(u_volumeTex, p * 0.5 + 0.5).x, u_densityFactor);
}

void main() {
	vec2 uv = screenPos;// * 2.0f - 1.0f;

	vec4 clip = vec4(uv, -1.0, 1.0);
	vec4 eye = vec4(vec2(u_invProjMat * clip), -1.0, 0.0);
	vec3 rayDir = vec3(u_invViewMat * eye);
	vec3 rayOrigin = u_invViewMat[3].xyz;

	Ray ray = Ray(rayOrigin, rayDir, 0.0f);

	float tmin, tmax;

	bool intersects = projectToCube(ray.origin, ray.direction, tmin, tmax);
	if(!intersects) {
		outColor = vec4(clearColor, 1.0f);
		return;
	}

	

	float sigma = u_absorptionFactor * u_stepSize * 5.0f;

	vec3 lightDir = normalize(u_lightPosition);

	/*float throughputLin = 0.0f;
	vec3 light = clearColor * 0.2f;

	for (float t = tmin; t < tmax; t += stepSize) {
		vec3 p = ray.origin + ray.direction * t;
		float density = texture(u_volumeTex, p * 0.5 + 0.5).x;

		if(density > 0.05f) {

			float tminLight, tmaxLight;
			vec3 lightAbsorption = vec3(0.0f);
			bool intersectsLight = projectToCube(p, lightDir, tminLight, tmaxLight);
			float lightDensity = 0.0f;
			float lightThroughput = 0.0f;
			if(intersectsLight) {
				for (float tLight = tminLight; tLight < tmaxLight; tLight += lightStepSize) {
					vec3 pLight = p + lightDir * tLight;
					float densityLight = texture(u_volumeTex, pLight * 0.5 + 0.5).x;
					lightDensity += densityLight;
				}
				
				lightThroughput = exp(-lightDensity * u_lightAbsorptionFactor * lightStepSize);
			}
			float dthroughput = density;
			throughputLin += dthroughput;
			light += mExp(throughputLin, sigma) * sigma * dthroughput * lightThroughput * u_lightColor;
		}
		
	}

	float throughput = mExp(throughputLin, sigma);*/

	float rayEnergy = 1.0f;
	vec3 rayColor = vec3(0);
	
	int maxSteps = u_numSteps;
	float t = tmin;
	while(rayEnergy > 0.0f && maxSteps > 0 && t < tmax) {
		vec3 p = ray.origin + ray.direction * t;
		float density = sampleDensity(p);
		float dEnergy = density * u_stepSize * u_absorptionFactor;
		rayEnergy -= dEnergy;

		vec3 lightEnergy = vec3(1.0f);
		float tminLight, tmaxLight;
		bool intersectsLight = projectToCube(p, lightDir, tminLight, tmaxLight);

		if(intersectsLight) {
			int maxLightSteps = u_numLightSteps;
			float tLight = tminLight;
			float accumulatedDensity = 0.0f;
			while(maxLightSteps > 0 && tLight < tmaxLight) {
				vec3 pLight = p + lightDir * tLight;
				float densityLight = sampleDensity(pLight);
				float dEnergyLight = densityLight * u_lightStepSize * u_lightAbsorptionFactor;
				accumulatedDensity += dEnergyLight;
				tLight += u_lightStepSize;
				maxLightSteps--;
			}
			lightEnergy = exp(-accumulatedDensity) * u_lightColor;
		}

		float scatteringAmount = Henyey_Greenstein(dot(ray.direction, lightDir), 0.5f);
		rayColor += lightEnergy * dEnergy;
		maxSteps--;
		t += u_stepSize;
	}

	rayColor += rayEnergy * clearColor;

	vec3 finalColor = rayColor;

	outColor = vec4(finalColor, 1.0f);
}