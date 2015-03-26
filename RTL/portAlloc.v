// port allocator mid stages

`include "global.v"

module portAlloc ( 
   req, avail, alloc, remain
);

input    [`WIDTH_PV-1:0]       req;
input    [`NUM_PORT-1:0]       avail;
output   [`NUM_PORT-1:0]       alloc, remain;

wire [`NUM_PORT-1:0] tempAlloc;
wire [`NUM_PORT-1:0] prodPort, deflectPort;
wire deflect;

assign tempAlloc = {1'b0,req} & avail;
assign deflect = (tempAlloc == 0) ? 1'b1 : 1'b0;

highestBit allocProdPort (tempAlloc, prodPort);
highestBit deflectToPort (avail, deflectPort);

assign alloc = deflect ?  deflectPort : prodPort;
assign remain = ~alloc & avail;

endmodule