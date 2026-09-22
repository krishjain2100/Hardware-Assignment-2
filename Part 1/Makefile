.PHONY: all compile run clean

# Default target executed when you just type 'make'
all: compile run

# Create build folder and compile the Verilog files into it
compile:
	mkdir -p build
	iverilog -o build/sim tb.v

# Run the simulation from the root directory so dump.vcd stays here
run:
	vvp build/sim

# Clean up the build folder and the generated waveform
clean:
	rm -rf build dump.vcd