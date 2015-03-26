// route computation for E port

`include "global.v"

module routeCompEast (valid, dstX, dstY, prodVector);

input valid;
input [`WIDTH_COORDINATE-1:0] dstX, dstY;
output [`NUM_PORT-1:0] prodVector;

wire [`WIDTH_COORDINATE-1:0] nextX, nextY;
assign nextX = (`CURRENT_POS_X+`WIDTH_COORDINATE'b1)%`SIZE_NETWORK;
assign nextY = `CURRENT_POS_Y;

wire [`WIDTH_COORDINATE:0] deltaX, deltaY;
assign deltaX = {1'b0,dstX} - {1'b0,nextX};
assign deltaY = {1'b0,dstY} - {1'b0,nextY};

// compute productive vector
wire doneX, doneY;
assign 	doneX = (deltaX == 0) ? 1 : 0;	
assign 	doneY = (deltaY == 0) ? 1 : 0;	
assign 	prodVector[1] = valid ? ~doneX & deltaX[`WIDTH_COORDINATE] : 1'b0;  // +X -> East
assign 	prodVector[0] = valid ? ~doneX & ~deltaX[`WIDTH_COORDINATE] : 1'b0;   // -X -> West
assign 	prodVector[3] = valid ? ~doneY & deltaY[`WIDTH_COORDINATE] : 1'b0;  // +Y -> North
assign 	prodVector[2] = valid ? ~doneY & ~deltaY[`WIDTH_COORDINATE] : 1'b0;   // -Y -> South
assign 	prodVector[4] = valid ? doneX & doneY : 1'b0;	// local port

endmodule