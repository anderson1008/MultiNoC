// 5 ports Xbar 

`include "global.v"

/*
   Has to hard code the input and output vector into seperate signals
   if merged, Modelsim prompts wired error.
*/

//module xbar5Ports (allocVector,dataInVector,dataOutVector);
module xbar5Ports (allocVector, din0, din1, din2, din3, din4, dout0, dout1, dout2, dout3, dout4);

input [`NUM_PORT*`NUM_PORT-1:0] allocVector;
//input [`NUM_PORT*`WIDTH_XBAR-1:0] dataInVector;
input [`WIDTH_XBAR-1:0] din0, din1, din2, din3, din4;
output [`WIDTH_XBAR-1:0] dout0, dout1, dout2, dout3, dout4;
//output [`NUM_PORT*`WIDTH_XBAR-1:0] dataOutVector;

wire [`NUM_PORT*`LOG_NUM_PORT-1:0] outSelVector, inSelVector;
wire [`LOG_NUM_PORT-1:0] inSel [0:`NUM_PORT-1];
wire [`LOG_NUM_PORT-1:0] outSel [0:`NUM_PORT-1];
wire [`WIDTH_XBAR-1:0] temp [0:`NUM_PORT-1][0:`NUM_PORT-1];
wire [`WIDTH_XBAR-1:0] din [0:`NUM_PORT-1];
wire [`WIDTH_XBAR-1:0] dout [0:`NUM_PORT-1];

xbarCtrl xbarCtrl (allocVector, outSelVector, inSelVector);

assign din[0] = din0;
assign din[1] = din1;
assign din[2] = din2;
assign din[3] = din3;
assign din[4] = din4;
assign dout0 = dout[0];
assign dout1 = dout[1];
assign dout2 = dout[2];
assign dout3 = dout[3];
assign dout4 = dout[4];

genvar i,j;
generate
   for (i=0; i<`NUM_PORT; i=i+1) begin : XbarInput
      assign inSel[i] = inSelVector[i*`LOG_NUM_PORT+:`LOG_NUM_PORT];
      assign outSel[i] = outSelVector[i*`LOG_NUM_PORT+:`LOG_NUM_PORT];
      //assign din[i] = dataInVector[i*`WIDTH_XBAR+:`WIDTH_XBAR]; 
      //assign dataOutVector[i*`WIDTH_XBAR+:`WIDTH_XBAR] = dout[i];

      demuxWrapper1to5 XBarDemux(din[i], outSel[i], temp[i][0], temp[i][1], temp[i][2], temp[i][3], temp[i][4]);
      muxWrapper5to1 XBarMux(temp[0][i], temp[1][i], temp[2][i], temp[3][i], temp[4][i], inSel[i], dout[i]);
   end
endgenerate



endmodule