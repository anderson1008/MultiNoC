// First available port

`include "global.v"

// Not parameterized
module firstbit (dataIn, dataOut);

input    [3:0]      dataIn;
output   [3:0]      dataOut;

assign dataOut [3] = dataIn[3];
assign dataOut [2] = ~dataIn[3] && dataIn[2];
assign dataOut [1] = ~dataIn[3] && ~dataIn[2] && dataIn[1]; 
assign dataOut [0] = ~dataIn[3] && ~dataIn[2] && ~dataIn[1] && dataIn[0];

endmodule 