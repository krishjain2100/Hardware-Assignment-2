void multiply(const int A[8][8], const int B[8][8], int C[8][8]); 

int main() {
    int A[8][8] = {0};
    int B[8][8] = {0};
    int C[8][8] = {0};
    
    for(int i = 0; i < 8; i++) {
        for(int j = 0; j < 8; j++) {
            A[i][j] = i + 1;       
            B[i][j] = j + 1;       
        }
    }

    multiply(A, B, C);

    if (C[0][0] == 8 && C[0][1] == 16 && C[1][0] == 16 && C[1][1] == 32) {
        return 99; 
    }
    return 1; // FAIL

}