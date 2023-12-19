#ifndef VOXEL_ARRAY_HPP
#define VOXEL_ARRAY_HPP

#include "gl_includes.hpp"
#include <random>
#include <iostream>
#include "gradient_noise.hpp"
#include "voronoi.hpp"

class VoxelArray {
public:
    GLuint sizeX, sizeY, sizeZ;
    glm::vec3* colorData;

    GLuint colorTextureID;

public:
    VoxelArray(GLuint sizeX, GLuint sizeY, GLuint sizeZ) {
        this->sizeX = sizeX;
        this->sizeY = sizeY;
        this->sizeZ = sizeZ;
        colorData = new glm::vec3[sizeX * sizeY * sizeZ];

        generateVoxelData();
        generateTexture();
    }

    float smin(float a, float b, float k) {
        float h = glm::clamp(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
        return glm::mix(a, b, h) - k*h*(1.0-h);
    }

    void generateVoxelData() {
        //gnd::gradient_noise<float, 3> noise(42);
        Voronoi voronoi(10, 42);
        srand(42);

        glm::vec3 spheresPos[5] {};
        for (int i = 0; i < 5; i++) {
            spheresPos[i] = glm::vec3(rand() % (sizeX/2) + sizeX/4, rand() % (sizeY/2) + sizeY/4, rand() % (sizeZ/2) + sizeZ/4);
        }
        float spheresRadius[5] {};
        for (int i = 0; i < 5; i++) {
            spheresRadius[i] = rand() % 10 + 5;
        }

        for (int i = 0; i < sizeX * sizeY * sizeZ; i++) {
            GLuint x =  i % sizeX;
            GLuint y = (i / sizeX) % sizeY;
            GLuint z =  i / (sizeX * sizeY);

            float dist = 1000000000.0f;
            for (int j = 0; j < 5; j++) {
                float d = glm::length(glm::vec3(x, y, z) - spheresPos[j]) - spheresRadius[j];
                dist = smin(dist, d, 1.0f);
            }

            float density = -dist;
            // Add voronoi noise
            float frequency = 0.01f;
            float amplitude = 5.0f;
            for(int i=0; i<5; i++) {
                density += amplitude * voronoi(glm::vec3(x, y, z) * frequency);
                frequency *= 2.0f;
                amplitude *= 0.5f;
            }
            //density += voronoi(glm::vec3(x, y, z) * 0.02f) * 5.0f;

            density = glm::clamp(density, 0.0f, 1.0f);

            colorData[i] = glm::vec3(density);
        }

        
        /*for (int i = 0; i < sizeX * sizeY * sizeZ; i++) {
            GLuint x =  i % sizeX;
            GLuint y = (i / sizeX) % sizeY;
            GLuint z =  i / (sizeX * sizeY);

            glm::vec3 normalizedPos = (glm::vec3(x, y, z) + glm::vec3(0.5f)) / glm::vec3(sizeX, sizeY, sizeZ);
            float frequency = 1.0f;
            float amplitude = 1.0f;
            float density = 0.0f;
            for(int i=0; i<5; i++) {
                density += amplitude * voronoi(normalizedPos * frequency);
                frequency *= 2.0f;
                amplitude *= 0.5f;
            }
            density *= pow(glm::min(1.4f-voronoi(normalizedPos * 0.3f), 1.0f), 5.0f);
            density = glm::clamp(density, 0.0f, 1.0f);

            density += (1-normalizedPos.y) * 0.1f;
            density *= (0.7f-glm::length(normalizedPos - glm::vec3(0.5f)));
            density += (1-normalizedPos.y) * 0.1f;
            colorData[i] = glm::vec3(glm::min(density, 1.0f));
            
        }*/
    }

    void generateTexture() {
        glActiveTexture(GL_TEXTURE0);

        glGenTextures(1, &colorTextureID);
        glBindTexture(GL_TEXTURE_3D, colorTextureID);

        glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_3D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

        glTexImage3D(GL_TEXTURE_3D, 0, GL_RGB, sizeX, sizeY, sizeZ, 0, GL_RGB, GL_FLOAT, colorData);
        glBindTexture(GL_TEXTURE_3D, 0);
    }

    ~VoxelArray() {
        delete[] colorData;

        glDeleteTextures(1, &colorTextureID);
    }
};

#endif // !VOXEL_ARRAY_HPP