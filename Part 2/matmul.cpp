void multiply(const int A[8][8], const int B[8][8], int C[8][8]) {
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            C[i][j] = 0; 
            for (int k = 0; k < 8; k++) {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
}