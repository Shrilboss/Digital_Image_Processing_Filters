// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Sun Nov 17 00:18:00 2019
// Host        : LAPTOP-0BRRARGR running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub {d:/Desktop/FINAL
//               SUBMISSION/Filters/FIlters/nexys_final.srcs/sources_1/ip/blk_mem_gen_0_1/blk_mem_gen_0_stub.v}
// Design      : blk_mem_gen_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_3,Vivado 2019.1" *)
module blk_mem_gen_0(clka, wea, addra, dina, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[14:0],dina[95:0],douta[95:0]" */;
  input clka;
  input [0:0]wea;
  input [14:0]addra;
  input [95:0]dina;
  output [95:0]douta;
endmodule
