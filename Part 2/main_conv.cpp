#include <cstdio>

void convolve(const int img[8][8], const int kernel[2][2], int output[7][7]);

int main() {
    int img[8][8] = {0};
    int kernel[2][2] = {{1, 0}, {0, -1}};
    int output[7][7] = {0}; 
    for(int i = 0; i < 8; i++) {
        for(int j = 0; j < 8; j++) {
            img[i][j] = i * 8 + j;
        }
    }

    convolve(img, kernel, output);

    if (output[0][0] == -9 && output[0][1] == -10 && output[1][0] == -17 && output[1][1] == -18) {
        return 2; 
    }

    return 1; // FAIL
}