// test bench for xbarCtrl

`include "global.v"

module tb_xbarCtrl ;

reg [`NUM_PORT-1:0] alloc [`NUM_PORT-1:0];

wire [`NUM_PORT*`NUM_PORT-1:0] allocVector;

wire [`NUM_PORT*`LOG_NUM_PORT-1:0] outSelVector, inSelVector;

wire  [`LOG_NUM_PORT-1:0] outSel [`NUM_PORT-1:0]; // 4-LOCAL; 3-N; 2-S; 1-E; 0-W;

wire  [`LOG_NUM_PORT-1:0] inSel [`NUM_PORT-1:0]; // 4-LOCAL; 3-N; 2-S; 1-E; 0-W;

genvar j;
generate 
   for (j=0; j<`NUM_PORT; j=j+1) begin : MergeSplit
      assign allocVector [j*`NUM_PORT+:`NUM_PORT] = alloc[j];
      assign outSel [j] = outSelVector [j*`LOG_NUM_PORT+:`LOG_NUM_PORT];
      assign inSel [j] = inSelVector [j*`LOG_NUM_PORT+:`LOG_NUM_PORT];
   end
endgenerate

xbarCtrl uutxbarCtrl(allocVector, outSelVector, inSelVector);

initial begin
   alloc[0] = 0; alloc[1] = 0; alloc[2] = 0; alloc[3] = 0; alloc[4] = 0;
   #10; alloc[0] = 5'b10000; alloc[1] = 5'b01000; alloc[2] = 5'b00100; alloc[3] = 5'b00010; alloc[4] = 5'b00001;
   #10; alloc[0] = 5'b01000; alloc[1] = 5'b00100; alloc[2] = 5'b00010; alloc[3] = 5'b00001; alloc[4] = 5'b10000;
   #10; alloc[0] = 5'b00100; alloc[1] = 5'b00010; alloc[2] = 5'b00001; alloc[3] = 5'b10000; alloc[4] = 5'b01000;
   #10; alloc[0] = 5'b00010; alloc[1] = 5'b00001; alloc[2] = 5'b10000; alloc[3] = 5'b01000; alloc[4] = 5'b00100;
   #10; alloc[0] = 5'b00001; alloc[1] = 5'b10000; alloc[2] = 5'b01000; alloc[3] = 5'b00100; alloc[4] = 5'b00010;
   #10; alloc[0] = 5'b10000; alloc[1] = 5'b01000; alloc[2] = 5'b00100; alloc[3] = 5'b00010; alloc[4] = 5'b00001;
end

initial begin
	# 100; $finish;	// simulation ends here.	
end




endmodule