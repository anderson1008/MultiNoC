// Eject local flit

`include "global.v"

module ejector (localVector, flit0, flit1, flit2, flit3, flit4, localFlit);

input		[`WIDTH_PORT-1:0]		flit0, flit1, flit2, flit3, flit4;
input    [`NUM_CHANNEL-1:0]   localVector;
output	[`WIDTH_PORT-1:0]		localFlit;

reg [`WIDTH_PORT-1:0] r_local=0;

always @ * begin
   case (localVector)
      `NUM_CHANNEL'b10000: r_local = flit4;
      `NUM_CHANNEL'b01000: r_local = flit3;
      `NUM_CHANNEL'b00100: r_local = flit2;
      `NUM_CHANNEL'b00010: r_local = flit1;
      `NUM_CHANNEL'b00001: r_local = flit0;      
      default: r_local = 0; // normally, it is impossible since conflicts have been resolved in PA.
   endcase
end

assign localFlit = r_local;


endmodule