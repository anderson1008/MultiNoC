// wrapper of mux

`include "global.v"

module muxWrapper6to1 (ina, inb, inc, ind, ine, inf, sel, out);

input [`WIDTH_XBAR-1:0] ina, inb, inc, ind, ine, inf;
input [2:0] sel;
output [`WIDTH_XBAR-1:0] out;

genvar i;
generate
   for (i=0; i<`WIDTH_XBAR; i=i+1) begin : XbarInput
      mux6to1 XBarMux(ina[i], inb[i], inc[i], ind[i], ine[i], inf[i], sel, out[i]);
   end
endgenerate

endmodule