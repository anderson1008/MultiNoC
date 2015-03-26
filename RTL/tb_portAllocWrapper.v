// test bench for portAllocWrapper

`include "global.v"

module tb_portAllocWrapper;

wire [`NUM_PORT*`NUM_PORT-1:0] reqVector; 
wire [`NUM_PORT*`NUM_PORT-1:0] allocVector; 

reg [`NUM_PORT-1:0] req [0:`NUM_PORT-1];
wire [`NUM_PORT-1:0] alloc [0:`NUM_PORT-1]; 

genvar i;
generate 
   for (i=0; i<`NUM_PORT; i=i+1) begin : MergeSplit
      assign reqVector[i*`NUM_PORT+:`NUM_PORT] = req[i];
      assign alloc[i] = allocVector[i*`NUM_PORT+:`NUM_PORT];
   end
endgenerate

portAllocWrapper uut_portAllocWrapper (reqVector, allocVector);

initial begin
   req[0] = `NUM_PORT'b00000; req[1] = `NUM_PORT'b00000; req[2] = `NUM_PORT'b00000; req[3] = `NUM_PORT'b00000; req[4] = `NUM_PORT'b00000;
   #10;
   req[0] = `NUM_PORT'b00001; req[1] = `NUM_PORT'b00001; req[2] = `NUM_PORT'b01000; req[3] = `NUM_PORT'b10000; req[4] = `NUM_PORT'b00100;
   #10;
   req[0] = `NUM_PORT'b00001; req[1] = `NUM_PORT'b00001; req[2] = `NUM_PORT'b01000; req[3] = `NUM_PORT'b10000; req[4] = `NUM_PORT'b01000;
end

endmodule