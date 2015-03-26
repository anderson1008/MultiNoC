// test bench of mux5to1

module tb_demux1to5;

reg din;
reg [2:0] sel;

wire out1, out2, out3, out4, out5;

demux1to5 uutDemux(din, sel, out1, out2, out3, out4, out5);


initial begin
   din = 0; sel = 3'b000;
   # 10; din = 1; sel = 3'b000;
   # 10; din = 1; sel = 3'b001;
   # 10; din = 1; sel = 3'b010;
   # 10; din = 1; sel = 3'b011;
   # 10; din = 1; sel = 3'b100;
   # 10; din = 1; sel = 3'b000;
   
end

initial begin
	# 100; $finish;	// simulation ends here.	
end

initial 
   // Print on the console
   $monitor ("At time %2t, din = %d sel = %d out1 = %d out2 = %d out3 = %d out4 = %d out5 = %d", $time, din, sel, out1, out2, out3, out4, out5);

endmodule