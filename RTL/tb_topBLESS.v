// testbench for topBLESS

`include "global.v"

module tb_topBLESS;

reg clk, reset;
reg [`WIDTH_PORT-1:0] dinW, dinE, dinS, dinN;
reg [`WIDTH_PORT-1:0] dinLocal, dinBypass;
reg [`WIDTH_PV-1:0]   PVBypass, PVLocal;

wire [`WIDTH_PORT-1:0] doutW, doutE, doutS, doutN;
wire [`WIDTH_PORT-1:0]  doutLocal, doutBypass;


topBLESS uut_topBLESS (clk, reset, dinW, dinE, dinS, dinN, dinLocal, dinBypass, PVBypass, PVLocal, doutW, doutE, doutS, doutN, doutLocal, doutBypass);


initial begin
   clk = 1'b0; reset = 1'b1;  
   dinW = 0;   dinE = 0;   dinS = 0;   dinN = 0;   dinLocal = 0;  dinBypass = 0; PVBypass = 0; PVLocal = 0;
   
   #10;
   reset = 1'b0;
   #10;
   reset = 1'b1;
   
   //Packet format (on the link)
   // [PKTID FLITID TIME POS_X POSY]
   // [6       2     8     4     4]  size = 24 
   // Port Arragement
   // 5-BYPASS 4-LOCAL; 3-N; 2-S; 1-E; 0-W;
   
   // case 1: no conflict
   dinW = {6'd1, 2'd0, 8'd15, 4'd0, 4'd1, `WIDTH_DATA'hA}; // N 3
   dinE = {6'd2, 2'd0, 8'd14, 4'd1, 4'd0, `WIDTH_DATA'hB}; // E 1
   dinS = {6'd3, 2'd0, 8'd13, 4'd3, 4'd0, `WIDTH_DATA'hC}; // W 0
   dinN = {6'd4, 2'd0, 8'd12, 4'd0, 4'd3, `WIDTH_DATA'hD}; // S 2
   #10; 
   dinBypass = {6'd5, 2'd0, 8'd1, 4'd0, 4'd3, `WIDTH_DATA'hE}; // (header doesn't matter)
   PVBypass = 5'b00010; // reqE -> bypass
   dinLocal = {6'd5, 2'd0, 8'd1, 4'd0, 4'd3, `WIDTH_DATA'hF}; 
   PVLocal = 5'b00010; // reqE -> throttle
   
   // case 2: Pkt1 wins;     
   dinW = {6'd1, 2'd0, 8'd10, 4'd1, 4'd0, `WIDTH_DATA'hA}; // E 1
   dinE = {6'd2, 2'd0, 8'd11, 4'd1, 4'd0, `WIDTH_DATA'hB}; // Bypass 5 -> 1 cycle ahead
   dinS = {6'd3, 2'd0, 8'd12, 4'd0, 4'd1, `WIDTH_DATA'hC}; // N 3
   dinN = {6'd4, 2'd0, 8'd13, 4'd0, 4'd0, `WIDTH_DATA'hD}; // Local 4 
   #10;
   dinBypass = {6'd5, 2'd0, 8'd1, 4'd0, 4'd3, `WIDTH_DATA'hE}; // (header doesn't matter)
   PVBypass = 5'b00001; // W 0
   dinLocal = {6'd5, 2'd0, 8'd1, 4'd0, 4'd3, `WIDTH_DATA'hF}; 
   PVLocal = 5'b00010; // reqE -> S 2
   
   // case 3: all four ports conflict -> Pkt5 wins.
   dinW = {6'd1, 2'd0, 8'd10, 4'd3, 4'd3, `WIDTH_DATA'hA}; // N 3
   dinE = {6'd2, 2'd0, 8'd5, 4'd3, 4'd3, `WIDTH_DATA'hB};  // S 2
   dinS = {6'd3, 2'd0, 8'd9, 4'd3, 4'd3, `WIDTH_DATA'hC};  // Bypass 5
   dinN = {6'd4, 2'd0, 8'd13, 4'd0, 4'd0, `WIDTH_DATA'hD}; // Local 4 
   #10;
   dinBypass = {6'd5, 2'd0, 8'd1, 4'd0, 4'd3, `WIDTH_DATA'hE}; // (header doesn't matter)
   PVBypass = 5'b00100; // reqS -> W
   dinLocal = {6'd5, 2'd0, 8'd1, 4'd0, 4'd3, `WIDTH_DATA'hF}; 
   PVLocal = 5'b00010; // E 1
end

always @ *
   #5 clk <= ~clk;
   
endmodule