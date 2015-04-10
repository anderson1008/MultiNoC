// route computation

`include "global.v"

module routeComp (valid, dstX, dstY, prodVector);

input valid;
input [`WIDTH_COORDINATE-1:0] dstX, dstY;
output [`WIDTH_PV-1:0] prodVector;

wire [`WIDTH_COORDINATE:0] deltaX, deltaY;
assign deltaX = {1'b0,dstX} - {1'b0,`CURRENT_POS_X};
assign deltaY = {1'b0,dstY} - {1'b0,`CURRENT_POS_Y};

wire [`WIDTH_COORDINATE:0] absDeltaX, absDeltaY;
assign absDeltaX = (deltaX>0) ? deltaX : ~deltaX + 1;
assign absDeltaY = (deltaY>0) ? deltaY : ~deltaY + 1;

wire [`WIDTH_COORDINATE:0] actualDeltaX, actualDeltaY;
assign actualDeltaX = (absDeltaX >= `SIZE_NETWORK/2) ? ((deltaX>0) ? (deltaX -`SIZE_NETWORK) : (deltaX + `SIZE_NETWORK)) : deltaX;
assign actualDeltaY = (absDeltaY >= `SIZE_NETWORK/2) ? ((deltaY>0) ? (deltaY -`SIZE_NETWORK) : (deltaY + `SIZE_NETWORK)) : deltaY;

// Port Arragement
// 4-LOCAL; 3-N; 2-S; 1-E; 0-W;

// compute productive vector
wire doneX, doneY;
assign 	doneX = (deltaX == 0) ? 1'b1 : 1'b0;	
assign 	doneY = (deltaY == 0) ? 1'b1 : 1'b0;	
assign 	prodVector[1] = valid ? ~doneX & ~actualDeltaX[`WIDTH_COORDINATE] : 1'b0;  // +X -> East
assign 	prodVector[0] = valid ? ~doneX & actualDeltaX[`WIDTH_COORDINATE] : 1'b0;   // -X -> West
assign 	prodVector[3] = valid ? ~doneY & ~actualDeltaY[`WIDTH_COORDINATE] : 1'b0;  // +Y -> North
assign 	prodVector[2] = valid ? ~doneY & actualDeltaY[`WIDTH_COORDINATE] : 1'b0;   // -Y -> South
assign 	prodVector[4] = valid ? doneX & doneY : 1'b0;	// local port

endmodule