// test bench for Permutation Network

`include "global.v"

module tb_permutationNetwork;

reg [`WIDTH_INTERNAL-1:0] din0, din1, din2, din3;
wire [`WIDTH_INTERNAL-1:0] dout0, dout1, dout2, dout3; // dout0 has highest priority (oldest); dout3 has lowest priority (lastest)

permutationNetwork uut_permutationNetwork (din0, din1, din2, din3, dout0, dout1, dout2, dout3);


initial begin
   din0 = 0; din1 = 0; din2 = 0; din3 = 0; 
   #10;
   din0 = {3'b0,5'b01000, 6'd1, 2'd0, 8'd15, 4'd15, 4'd15, `WIDTH_DATA'hA}; 
   din1 = {3'b0,5'b00100, 6'd2, 2'd0, 8'd14, 4'd15, 4'd15, `WIDTH_DATA'hB};  
   din2 = {3'b0,5'b00010, 6'd3, 2'd0, 8'd13, 4'd15, 4'd15, `WIDTH_DATA'hC}; 
   din3 = {3'b0,5'b00001, 6'd4, 2'd0, 8'd12, 4'd15, 4'd15, `WIDTH_DATA'hD};

   #10;
   din0 = {3'b0,5'b01000, 6'd1, 2'd0, 8'd10, 4'd15, 4'd15, `WIDTH_DATA'hA}; 
   din1 = {3'b0,5'b00100, 6'd2, 2'd0, 8'd11, 4'd15, 4'd15, `WIDTH_DATA'hB};  
   din2 = {3'b0,5'b00010, 6'd3, 2'd0, 8'd12, 4'd15, 4'd15, `WIDTH_DATA'hC}; 
   din3 = {3'b0,5'b00001, 6'd4, 2'd0, 8'd13, 4'd15, 4'd15, `WIDTH_DATA'hD};   
   
   #10;
   din0 = {3'b0,5'b01000, 6'd1, 2'd0, 8'd10, 4'd15, 4'd15, `WIDTH_DATA'hA}; 
   din1 = {3'b0,5'b00100, 6'd2, 2'd0, 8'd5, 4'd15, 4'd15, `WIDTH_DATA'hB};  
   din2 = {3'b0,5'b00010, 6'd3, 2'd0, 8'd9, 4'd15, 4'd15, `WIDTH_DATA'hC}; 
   din3 = {3'b0,5'b00001, 6'd4, 2'd0, 8'd18, 4'd15, 4'd15, `WIDTH_DATA'hD}; 

end

endmodule