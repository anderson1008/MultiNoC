// demux wrapper

`include "global.v"

module demuxWrapper1to5 (din, sel, out1, out2, out3, out4, out5);

input [`WIDTH_XBAR-1:0] din;
input [2:0] sel;
output [`WIDTH_XBAR-1:0] out1, out2, out3, out4, out5;

genvar i;
generate
   for (i=0; i<`WIDTH_XBAR; i=i+1) begin : XbarOutput
      demux1to5 xBarDemux(din[i], sel, out1[i], out2[i], out3[i], out4[i], out5[i]);
   end
endgenerate

endmodule