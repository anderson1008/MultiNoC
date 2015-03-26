// wrapper of mux

`include "global.v"

module muxWrapper2to1 (ina, inb, sel, out);

input [`WIDTH_INTERNAL_PV-1:0] ina, inb;
input sel;
output [`WIDTH_INTERNAL_PV-1:0] out;

genvar i;
generate
   for (i=0; i<`WIDTH_INTERNAL_PV; i=i+1) begin : PermuteMux
      mux2to1 mux (ina[i], inb[i], sel, out[i]);
   end
endgenerate

endmodule