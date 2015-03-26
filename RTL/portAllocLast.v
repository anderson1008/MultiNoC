// port allocator at last stage

`include "global.v"

module portAllocLast ( 
   req, avail, alloc
);

input    [`WIDTH_PV-1:0]       req;
input    [`NUM_PORT-1:0]       avail;
output   [`NUM_PORT-1:0]       alloc;

wire [`NUM_PORT-1:0] tempAlloc, prodPort, deflectPort;
wire deflect;

assign tempAlloc = {1'b0,req} & avail;
assign deflect = (tempAlloc == 0) ? 1'b1 : 1'b0;

highestBit allocProdPort (tempAlloc, prodPort);
highestBit deflectToPort (avail, deflectPort);

assign alloc = deflect ?  deflectPort : prodPort;

endmodule