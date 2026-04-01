TOP = quadra_top

RTL = rtl-model/quadra_top.vs \
      rtl-model/quadra.vs \
      rtl-model/lut.vs \
      rtl-model/square.vs

CPP = c++-model/Quadra.cpp \
      c++-model/QuadraTb.cpp

all:
	verilator -Wall --cc $(RTL) --exe $(CPP) --trace --top-module $(TOP)
	make -C obj_dir -f V$(TOP).mk
	./obj_dir/V$(TOP)

clean:
	rm -rf obj_dir *.vcd