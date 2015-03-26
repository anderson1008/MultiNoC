// demux wrapper

`include "global.v"

module demuxWrapper1to2 (din, sel, out1, out2);

input [`WIDTH_INTERNAL_PV-1:0] din;
input sel;
output [`WIDTH_INTERNAL_PV-1:0] out1, out2;

genvar i;
generate
   for (i=0; i<`WIDTH_INTERNAL_PV; i=i+1) begin : PermuteDemux
      demux1to2 demux(din[i], sel, out1[i], out2[i]);
   end
endgenerate

endmodule