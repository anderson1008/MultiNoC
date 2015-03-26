// Permutation Network

`include "global.v"

module permutationNetwork (din0, din1, din2, din3, dout0, dout1, dout2, dout3);

input [`WIDTH_INTERNAL_PV-1:0] din0, din1, din2, din3;
output [`WIDTH_INTERNAL_PV-1:0] dout0, dout1, dout2, dout3; // dout0 has highest priority (oldest); dout3 has lowest priority (lastest)

wire	[`WIDTH_INTERNAL_PV-1:0] swapFlit [3:0];
wire	[`WIDTH_INTERNAL_PV-1:0] straightFlit [3:0];
wire  swap [0:5];

// (1: downward sort; 0: upward sort)
arbiterPN arbiterPN00 (din3[`POS_TIME], din2[`POS_TIME], 1'b0, swap[0]);
arbiterPN arbiterPN01 (din1[`POS_TIME], din0[`POS_TIME], 1'b1, swap[1]);
arbiterPN arbiterPN10 (straightFlit[0][`POS_TIME], swapFlit[1][`POS_TIME], 1'b0, swap[2]);
arbiterPN arbiterPN11 (swapFlit[0][`POS_TIME], straightFlit[1][`POS_TIME], 1'b0, swap[3]);
arbiterPN arbiterPN20 (straightFlit[2][`POS_TIME], swapFlit[3][`POS_TIME], 1'b0, swap[4]);
arbiterPN arbiterPN21 (swapFlit[2][`POS_TIME], straightFlit[3][`POS_TIME], 1'b0, swap[5]);

permuterBlock PN00(din3, din2, swap[0], straightFlit[0], swapFlit[0]);
permuterBlock PN01(din1, din0, swap[1], swapFlit[1], straightFlit[1]);
permuterBlock PN10(straightFlit[0], swapFlit[1], swap[2], straightFlit[2], swapFlit[2]);
permuterBlock PN11(swapFlit[0], straightFlit[1], swap[3], swapFlit[3], straightFlit[3]);
permuterBlock PN20(straightFlit[2], swapFlit[3], swap[4], dout0, dout1);
permuterBlock PN21(swapFlit[2], straightFlit[3], swap[5], dout2, dout3);

endmodule