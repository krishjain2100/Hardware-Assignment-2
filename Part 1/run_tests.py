import os
import json
import subprocess
import glob

def parse_hex_file(filepath, width_in_bits):
    values = []
    if not os.path.exists(filepath):
        return values
    with open(filepath, 'r') as f:
        for line in f:
            line = line.split('//')[0].strip()
            if not line:
                continue
            for token in line.split():
                val = int(token, 16)
                if val >= (1 << (width_in_bits - 1)):
                    val -= (1 << width_in_bits)
                values.append(val)
    return values

def run_test_suite(suite_dir):
    config_path = os.path.join(suite_dir, "config.json")
    
    # Removed the check for local tb_*.v files
    if not os.path.exists(config_path):
        print(f"Skipping {suite_dir}: Missing config.json.")
        return False

    with open(config_path, "r") as f:
        config = json.load(f)
    
    M = config["M"]
    K = config["K"]
    N = config["N"]
    WIDTH_IN = config.get("WIDTH_IN", 8)
    WIDTH_OUT = config.get("WIDTH_OUT", 32)
    out_matrix_path = os.path.join(suite_dir, "matrix_c.txt")

    print(f"\n==============================================")
    print(f"Running Suite: {os.path.basename(suite_dir)} ({M}x{K} * {K}x{N})")
    print(f"==============================================")

    # Clean old outputs
    if os.path.exists(out_matrix_path):
        os.remove(out_matrix_path)

    design_files = glob.glob("design/*.v")
    
    if not design_files:
        print("COMPILATION FAILED: No .v files found in design/ folder.")
        return False

    # Compile using iverilog (including design files from parent folder)
    sim_bin = os.path.join(suite_dir, "sim_exec")
    compile_cmd = [
        "iverilog", "-g2012", 
        "-I", "design", 
        f"-DM_VAL={M}", 
        f"-DK_VAL={K}", 
        f"-DN_VAL={N}",
        f"-DWIDTH_IN_VAL={WIDTH_IN}",    
        f"-DWIDTH_OUT_VAL={WIDTH_OUT}",
        f"-DFILE_A=\"{os.path.join(suite_dir, 'matrix_a.txt')}\"",
        f"-DFILE_B=\"{os.path.join(suite_dir, 'matrix_b.txt')}\"",
        f"-DFILE_C=\"{out_matrix_path}\"",
        "-o", sim_bin, 
        "testbench/tb_universal.v" 
    ] + design_files 
    
    comp_res = subprocess.run(compile_cmd, capture_output=True, text=True)

    if comp_res.returncode != 0:
        print(f"COMPILATION FAILED:\n{comp_res.stderr}")
        return False

    # Run simulation via vvp
    sim_res = subprocess.run(["vvp", sim_bin], capture_output=True, text=True)
    if sim_res.returncode != 0:
        print(f"SIMULATION RUNTIME ERROR:\n{sim_res.stderr}")
        return False

    # Clean up simulation binary
    if os.path.exists(sim_bin):
        os.remove(sim_bin)

    # Verify against Golden Software Reference
    try:
        a_flat = parse_hex_file(os.path.join(suite_dir, "matrix_a.txt"), WIDTH_IN)
        b_flat = parse_hex_file(os.path.join(suite_dir, "matrix_b.txt"), WIDTH_IN)
        c_flat = parse_hex_file(out_matrix_path, WIDTH_OUT)
    except Exception as e:
        print(f"Error reading result files: {e}")
        return False

    if len(c_flat) != M * N:
        print(f"FAIL: Output matrix size mismatch! Expected {M*N} elements, got {len(c_flat)}.")
        return False

    A = [a_flat[i * K : (i + 1) * K] for i in range(M)]
    B = [b_flat[i * N : (i + 1) * N] for i in range(K)]
    HW_C = [c_flat[i * N : (i + 1) * N] for i in range(M)]

    GOLD_C = [
        [sum(A[i][p] * B[p][j] for p in range(K)) for j in range(N)]
        for i in range(M)
    ]

    match = True
    for i in range(M):
        for j in range(N):
            if HW_C[i][j] != GOLD_C[i][j]:
                match = False
                print(f"  [MISMATCH] C[{i}][{j}] -> HW: {HW_C[i][j]}, Expected: {GOLD_C[i][j]}")

    if match:
        print(f"RESULT: PASS ({M}x{N} matrix validated successfully)")
        return True
    else:
        print(f"RESULT: FAIL")
        return False

def main():
    suites = sorted([os.path.join("test_suite", d) for d in os.listdir("test_suite") if os.path.isdir(os.path.join("test_suite", d))])
    
    if not suites:
        print("No test suites found inside test_suite/")
        return

    passed_count = 0
    for suite in suites:
        if run_test_suite(suite):
            passed_count += 1

    print(f"\n==============================================")
    print(f"TEST SUMMARY: {passed_count}/{len(suites)} suites passed.")
    print(f"==============================================")

if __name__ == "__main__":
    main()