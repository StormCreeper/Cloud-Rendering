#ifndef VOXEL_ARRAY_HPP
#define VOXEL_ARRAY_HPP

#include "gl_includes.hpp"
#include <random>
#include <iostream>

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

    void generateVoxelData() {
        for (int i = 0; i < sizeX * sizeY * sizeZ; i++) {
            GLuint x =  i % sizeX;
            GLuint y = (i / sizeX) % sizeY;
            GLuint z =  i / (sizeX * sizeY);

            glm::vec3 normalizedPos = (glm::vec3(x, y, z) + glm::vec3(0.5f)) / glm::vec3(sizeX, sizeY, sizeZ) * 2.0f - 1.0f;

            colorData[i] = glm::vec3(0.0f);
            if(glm::length(normalizedPos) < 1.0f) {
                colorData[i] = glm::vec3(1.0f);
            }
        }
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