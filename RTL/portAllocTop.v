`include "global.v"

module portAllocTop ( 
   req, alloc, remain
);

input    [`WIDTH_PV-1:0]       req;
output   [`NUM_PORT-1:0]       alloc, remain;

wire [`NUM_PORT-1:0]  temp;
assign temp = {1'b0, req};

highestBit allocProdPort (temp, alloc);

assign remain = ~alloc;

endmodule