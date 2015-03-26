// test bench of mux5to1

module tb_mux5to1;

reg ina, inb, inc, ind, ine;
reg [2:0] sel;

wire out;

mux5to1 uutMux(ina, inb, inc, ind, ine, sel, out);


initial begin
   ina = 0; inb = 0; inc = 0; ind = 0; ine = 0; sel = 3'b000;
   # 10; ina = 1; inb = 0; inc = 0; ind = 0; ine = 0; sel = 3'b000;
   # 10; ina = 0; inb = 1; inc = 0; ind = 0; ine = 0; sel = 3'b001;
   # 10; ina = 0; inb = 0; inc = 1; ind = 0; ine = 0; sel = 3'b010;
   # 10; ina = 0; inb = 0; inc = 0; ind = 1; ine = 0; sel = 3'b011;
   # 10; ina = 0; inb = 0; inc = 0; ind = 0; ine = 1; sel = 3'b100;
   # 10; ina = 0; inb = 1; inc = 1; ind = 1; ine = 1; sel = 3'b000;
end

initial begin
	# 100; $finish;	// simulation ends here.	
end

initial 
   // Print on the console
   $monitor ("At time %2t, ina = %d inb = %d inc = %d ind = %d ine = %d sel = %d out = %d", $time, ina, inb, inc, ind, ine, sel, out);

endmodule