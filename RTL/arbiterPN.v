// arbiter for permutation network

`include "global.v"

module arbiterPN (time0, time1, mode, swap);

input [`WIDTH_TIME-1:0] time0, time1;
input    mode;
output   swap;

/*
   mode
   0: flit0 has higher priority
   1: flit1 has higher priority
*/
wire [`WIDTH_TIME-1:0] temp0, temp1;
assign temp0 = (time0==0) ? `MAX_TIME : time0;
assign temp1 = (time1==0) ? `MAX_TIME : time1;

assign swap = (mode == 0) ? (temp1 < temp0) : (temp0 < temp1);

endmodule