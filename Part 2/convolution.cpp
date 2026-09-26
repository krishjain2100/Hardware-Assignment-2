void convolve(const int img[8][8], const int kernel[2][2], int output[7][7]) {
    for (int i = 0; i < 7; i++) {
        for (int j = 0; j < 7; j++) {
            output[i][j] = 0;
            for (int ki = 0; ki < 2; ki++) {
                for (int kj = 0; kj < 2; kj++) {
                    output[i][j] += img[i + ki][j + kj] * kernel[ki][kj];
                }
            }
        }
    }
}
