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

    printf("\nConvolution Result (First 2x2 block):\n");
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < 2; j++) {
            printf("%d ", output[i][j]);
        }
        printf("\n");
    }

    return 0;
}