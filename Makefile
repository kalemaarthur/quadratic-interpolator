
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
