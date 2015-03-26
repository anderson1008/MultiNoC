`include "global.v"

module tb_xbar5Ports;

wire [`NUM_PORT*`NUM_PORT-1:0] allocVector;
//wire [`NUM_PORT*`WIDTH_INTERNAL-1:0] dataInVector;
//wire [`NUM_PORT*`WIDTH_INTERNAL-1:0] dataOutVector;

reg [`NUM_PORT-1:0] alloc [0:`NUM_PORT-1];
//reg [`WIDTH_INTERNAL-1:0] din [0:`NUM_PORT-1];
//wire [`WIDTH_INTERNAL-1:0] dout [0:`NUM_PORT-1];

reg [`WIDTH_XBAR-1:0] din0, din1, din2, din3, din4;
wire [`WIDTH_XBAR-1:0] dout0, dout1, dout2, dout3, dout4;

genvar j;
generate 
   for (j=0; j<`NUM_PORT; j=j+1) begin : MergeSplit
      assign allocVector [j*`NUM_PORT+:`NUM_PORT] = alloc[j];
      //assign dataInVector [j*`WIDTH_INTERNAL+:`WIDTH_INTERNAL] = din[j];
      //assign dout[j] = dataOutVector [j*`WIDTH_INTERNAL+:`WIDTH_INTERNAL];
   end
endgenerate


//xbar5Ports uut_xbar5Ports (allocVector,dataInVector,dataOutVector);
xbar5Ports uut_xbar5Ports (allocVector, din0, din1, din2, din3, din4, dout0, dout1, dout2, dout3, dout4);




initial begin
   alloc[0] = 0; alloc[1] = 0; alloc[2] = 0; alloc[3] = 0; alloc[4] = 0;
   din0 = `WIDTH_XBAR'hA;   din1 = `WIDTH_XBAR'hB;   din2 = `WIDTH_XBAR'hC;   din3 = `WIDTH_XBAR'hD;   din4 = `WIDTH_XBAR'hE;
   #10; 
   alloc[0] = 5'b10000; alloc[1] = 5'b01000; alloc[2] = 5'b00100; alloc[3] = 5'b00010; alloc[4] = 5'b00001;
   //din[0] = `WIDTH_INTERNAL'hA;   din[1] = `WIDTH_INTERNAL'hB;   din[2] = `WIDTH_INTERNAL'hC;   din[3] = `WIDTH_INTERNAL'hD;   din[4] = `WIDTH_INTERNAL'hE;
   #10; alloc[0] = 5'b01000; alloc[1] = 5'b00100; alloc[2] = 5'b00010; alloc[3] = 5'b00001; alloc[4] = 5'b10000;
   #10; alloc[0] = 5'b00100; alloc[1] = 5'b00010; alloc[2] = 5'b00001; alloc[3] = 5'b10000; alloc[4] = 5'b01000;
   #10; alloc[0] = 5'b00010; alloc[1] = 5'b00001; alloc[2] = 5'b10000; alloc[3] = 5'b01000; alloc[4] = 5'b00100;
   #10; alloc[0] = 5'b00001; alloc[1] = 5'b10000; alloc[2] = 5'b01000; alloc[3] = 5'b00100; alloc[4] = 5'b00010;
   #10; alloc[0] = 5'b10000; alloc[1] = 5'b01000; alloc[2] = 5'b00100; alloc[3] = 5'b00010; alloc[4] = 5'b00001;
end

endmodule