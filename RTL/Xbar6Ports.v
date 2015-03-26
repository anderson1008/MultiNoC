// 6 ports Xbar 

`include "global.v"


module xbar6Ports (allocVector, din0, din1, din2, din3, din4, dinBypass, dout0, dout1, dout2, dout3, dout4, doutBypass);

input [`NUM_PORT*`NUM_PORT-1:0] allocVector;
input [`WIDTH_XBAR-1:0] dinBypass, din0, din1, din2, din3, din4;
output [`WIDTH_XBAR-1:0] dout0, dout1, dout2, dout3, dout4, doutBypass;

wire [`NUM_PORT*`LOG_NUM_PORT-1:0] outSelVector, inSelVector;
wire [`LOG_NUM_PORT-1:0] inSel [0:`NUM_PORT-1];
wire [`LOG_NUM_PORT-1:0] outSel [0:`NUM_PORT-1];
wire [`WIDTH_XBAR-1:0] temp [0:`NUM_PORT-1][0:`NUM_PORT-1];
wire [`WIDTH_XBAR-1:0] din [0:`NUM_PORT-1];
wire [`WIDTH_XBAR-1:0] dout [0:`NUM_PORT-1];

xbarCtrl xbarCtrl (allocVector, outSelVector, inSelVector);

assign din[0] = dinBypass;
assign din[1] = din0;
assign din[2] = din1;
assign din[3] = din2;
assign din[4] = din3;
assign din[5] = din4;
assign dout0 = dout[0];
assign dout1 = dout[1];
assign dout2 = dout[2];
assign dout3 = dout[3];
assign dout4 = dout[4];
assign doutBypass = dout[5];

genvar i,j;
generate
   for (i=0; i<`NUM_PORT; i=i+1) begin : XbarInput
      assign inSel[i] = inSelVector[i*`LOG_NUM_PORT+:`LOG_NUM_PORT];
      assign outSel[i] = outSelVector[i*`LOG_NUM_PORT+:`LOG_NUM_PORT];

      demuxWrapper1to6 XBarDemux(din[i], outSel[i], temp[i][0], temp[i][1], temp[i][2], temp[i][3], temp[i][4], temp[i][5]);
      muxWrapper6to1 XBarMux(temp[0][i], temp[1][i], temp[2][i], temp[3][i], temp[4][i], temp[5][i], inSel[i], dout[i]);
   end
endgenerate


endmodule