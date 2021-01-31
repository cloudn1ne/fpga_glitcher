
upload: top.bin firmware.bin
	tinyprog --pyserial -p top.bin -u firmware.bin

top.json: top.v spimemio.v simpleuart.v picosoc.v picorv32.v pll.v glitcher.v cdc.v
	yosys -p 'synth_ice40 -top top -json top.json' $^ 

top.asc: top.pcf top.json
#	sed -i -e 's/clang.*/\",/g' top.json
	nextpnr-ice40 --lp8k --package cm81 --json top.json --pcf top.pcf --asc $@ #--ignore-loops

top.bin: top.asc
	icetime -d hx8k -c 16 -mtr top.rpt top.asc
	icepack top.asc top.bin


firmware.elf: ./firmware/sections.lds ./firmware/start.S ./firmware/firmware.c
	riscv32-unknown-elf-gcc -march=rv32imc -nostartfiles -Wl,-Bstatic,-T,./firmware/sections.lds,--strip-debug,-Map=./firmware/firmware.map,--cref  -ffreestanding -nostdlib -o firmware.elf ./firmware/start.S ./firmware/firmware.c

firmware.bin: firmware.elf
	riscv32-unknown-elf-objcopy -O binary firmware.elf firmware.bin

pll:
	icepll -i 16 -o 75 -m -f pll.v

sim:    cdc.v glitcher_tb.v glitcher.v 
	iverilog -o ./sim/glitcher -c ./sim/glitcher.files
	vvp -N ./sim/glitcher

clean:
	rm -f firmware.elf firmware.bin firmware/firmware.map \
	      top.blif top.log top.asc top.rpt top.bin top.json-e top.json firmware.bin firmware.elf glitcher.vcd

