
.PHONY: all sim verify clean

RTL = rtl-model/quadra_top.sv \
      rtl-model/quadra.sv \
      rtl-model/lut.sv \
      rtl-model/square.sv

all: verify

sim:
	iverilog -g2012 -s quadra_tb \
		-I rtl-model -o sim.vvp \
		rtl-model/quadra_tb.sv $(RTL)
	vvp sim.vvp

verify:
	python3 verification/verify_rtl.py

clean:
	rm -f sim.vvp wave.vcd verify_sim.vvp vectors.mem

# C++ vs RTL cross-verification
AC_TYPES_INCLUDE ?= $(HOME)/ac_types/include

.PHONY: compare

compare: verify
	g++ -std=c++17 -O2 -Wall \
		-I$(AC_TYPES_INCLUDE) \
		c++-model/compare_rtl.cpp \
		c++-model/Quadra.cpp \
		-o c++-model/CompareRTL
	./c++-model/CompareRTL


# Generic hardware synthesis using Yosys
.PHONY: synth

synth:
	cd rtl-model && yosys -Q \
		-l ../yosys_synthesis.log \
		-p 'read_verilog -sv -I. quadra_top.sv quadra.sv lut.sv square.sv; hierarchy -check -top quadra_top; synth -top quadra_top; check -assert; stat'
	@echo "Synthesis completed successfully."
	@echo "Report: yosys_synthesis.log"
