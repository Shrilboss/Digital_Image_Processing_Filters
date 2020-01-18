onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib blk_parrotproper_opt

do {wave.do}

view wave
view structure
view signals

do {blk_parrotproper.udo}

run -all

quit -force
