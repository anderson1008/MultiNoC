// Top module for multi-noc router

`include "global.v"

module topMultiNoC (clk, reset, dinW1, dinE1, dinS1, dinN1, dinLocal1, doutW1, doutE1, doutS1, doutN1, doutLocal1, dinW2, dinE2, dinS2, dinN2, dinLocal2, doutW2, doutE2, doutS2, doutN2, doutLocal2);

input clk, reset;
input [`WIDTH_PORT-1:0] dinW1, dinE1, dinS1, dinN1, dinLocal1, dinW2, dinE2, dinS2, dinN2, dinLocal2;
output [`WIDTH_PORT-1:0] doutW1, doutE1, doutS1, doutN1, doutLocal1, doutW2, doutE2, doutS2, doutN2, doutLocal2;

wire [`WIDTH_PORT-1:0] bypass [1:0];

topBLESS router1 (clk, reset, dinW1, dinE1, dinS1, dinN1, dinLocal1, bypass[1], doutW1, doutE1, doutS1, doutN1, doutLocal1, bypass[0]);
topBLESS router2 (clk, reset, dinW2, dinE2, dinS2, dinN2, dinLocal2, bypass[0], doutW2, doutE2, doutS2, doutN2, doutLocal2, bypass[1]);

endmodule