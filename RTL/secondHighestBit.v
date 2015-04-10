// second highest bit

`include "global.v"

module secondHighestBit (dataIn, dataOut);

input    [3:0]      dataIn;
output   [3:0]      dataOut;

reg   [3:0]      r_dataOut = 4'b0;

// In this case, there are at least two ports avaliable.

always @ (*) begin
   casex (dataIn)
      4'b11XX: r_dataOut = 4'b0100;
      4'b101X: r_dataOut = 4'b0010;
      4'b011X: r_dataOut = 4'b0010;
      4'b1001: r_dataOut = 4'b0001;
      4'b0101: r_dataOut = 4'b0001;
      4'b0011: r_dataOut = 4'b0001;
      default: r_dataOut = 4'bxxxx; // it is impossible. something must be wrong.
   endcase
end

assign dataOut = r_dataOut;

endmodule