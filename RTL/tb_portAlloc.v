// test bench port alloctor

`include "global.v"

module tb_portAlloc;

reg [`NUM_PORT-1:0]  req, avail;
wire [`NUM_PORT-1:0]  alloc, remain;

portAlloc uut_portAlloc( req, avail, alloc, remain );

initial begin
   req = `NUM_PORT'b00000;
   avail = `NUM_PORT'b11111;  
   #10;
   req = `NUM_PORT'b10000; 
   avail = `NUM_PORT'b11111;
   #10;
   req = `NUM_PORT'b10000; 
   avail = `NUM_PORT'b10111;
   #10;
   req = `NUM_PORT'b01000; 
   avail = `NUM_PORT'b10111;
   #10;
   req = `NUM_PORT'b01010; 
   avail = `NUM_PORT'b10111;
   #10;
   req = `NUM_PORT'b01011; 
   avail = `NUM_PORT'b10111;
  
end

initial 
   // Print on the console
   $monitor ("At time %2t, req = %b avail = %b alloc = %b remain = %b ", $time, req, avail, alloc, remain);
   
initial begin
	# 100; $finish;	// simulation ends here.	
end

endmodule