// highest bit

`include "global.v"

// Not parameterized
module highestBit5 (dataIn, dataOut);

input    [4:0]      dataIn;
output   [4:0]      dataOut;

assign dataOut [4] = dataIn[4];
assign dataOut [3] = ~dataIn[4] && dataIn[3];
assign dataOut [2] = ~dataIn[4] && ~dataIn[3] && dataIn[2];
assign dataOut [1] = ~dataIn[4] && ~dataIn[3] && ~dataIn[2] && dataIn[1]; 
assign dataOut [0] = ~dataIn[4] && ~dataIn[3] && ~dataIn[2] && ~dataIn[1] && dataIn[0];

endmodule 