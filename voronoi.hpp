#ifndef VORONOI_HPP
#define VORONOI_HPP

#include <glm/glm.hpp>
#include <random>

class Voronoi {
private:
    int num {};
    int seed {};
    glm::vec3* points {};
public:
    Voronoi(int num, int seed) {
        this->num = num;
        this->seed = seed;

        points = new glm::vec3[num*num*num];

        std::mt19937 gen(seed);

        for (int i = 0; i < num*num*num; i++) {
            float localX = gen() / (float)gen.max();
            float localY = gen() / (float)gen.max();
            float localZ = gen() / (float)gen.max();

            points[i] = glm::vec3(localX, localY, localZ);
        }
    }

    glm::vec3 getPoint(glm::ivec3 pos) {
        int x = pos.x % num;
        int y = pos.y % num;
        int z = pos.z % num;
        return points[x + y * num + z * num * num];
    }

    float operator()(glm::vec3 pos) {
        // Set the pos in the range [0, 1]
        pos = glm::fract(pos);
        glm::vec3 intPos = pos * (float)num;
        float minDistance = 1000000.0f;
        for(int i=-1; i<=1; i++) {
            for(int j=-1; j<=1; j++) {
                for(int k=-1; k<=1; k++) {
                    glm::vec3 point = getPoint(glm::ivec3(intPos) + glm::ivec3(i, j, k));
                    glm::vec3 localPos = glm::fract(pos * (float)num) - glm::vec3(i, j, k);
                    float distance = glm::length(point - localPos);
                    if(distance < minDistance) {
                        minDistance = distance;
                    }
                }
            }
        }
        return minDistance;
    }

    ~Voronoi() {
        delete[] points;
    }
};


#endif // VOXEL_ARRAY_HPP