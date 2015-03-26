// Top wrapper of baseline BLESS router with Look Ahead Routing

`include "global.v"

module topBLESS (clk, reset, dinW, dinE, dinS, dinN, dinLocal, dinBypass, doutW, doutE, doutS, doutN, doutLocal, doutBypass);

input clk, reset;
input [`WIDTH_PORT-1:0] dinW, dinE, dinS, dinN;
input [`WIDTH_PORT-1:0] dinLocal, dinBypass;
output [`WIDTH_PORT-1:0] doutW, doutE, doutS, doutN;
output [`WIDTH_PORT-1:0]  doutLocal, doutBypass;

reg  [`WIDTH_INTERNAL-1:0] r_dinW, r_dinE, r_dinS, r_dinN;
reg [`WIDTH_INTERNAL-1:0] r_dinLocal, r_dinBypass;

always @ (posedge clk or negedge reset) begin
   if (~reset) begin
      r_dinW <= 0;
      r_dinE <= 0;
      r_dinS <= 0;
      r_dinN <= 0;
      r_dinLocal <= 0;
      r_dinBypass <= 0;
   end
   
   else begin
      if (dinW != 0)
         r_dinW <= {1'b1,dinW};
      else
         r_dinW <= 0;
         
      if (dinE != 0)
         r_dinE <= {1'b1,dinE};
      else
         r_dinE <= 0;
         
      if (dinS != 0)
         r_dinS <= {1'b1,dinS};
      else
         r_dinS <= 0;
         
      if (dinN != 0)
         r_dinN <= {1'b1,dinN};
      else
         r_dinN <= 0;
         
      if (dinLocal != 0)
         r_dinLocal <= {1'b1,dinLocal};
      else 
         r_dinLocal <= 0;

      if (dinBypass != 0)
         r_dinBypass <= {1'b1,dinBypass};
      else
         r_dinBypass <= 0;
   end
end


wire [`WIDTH_PV-1:0] prodVector [0:`NUM_PORT-1];
routeComp routeCompWest (r_dinW[`WIDTH_INTERNAL-1], r_dinW[`POS_X_DST], r_dinW[`POS_Y_DST], prodVector[0]);
routeComp routeCompEast (r_dinE[`WIDTH_INTERNAL-1], r_dinE[`POS_X_DST], r_dinE[`POS_Y_DST], prodVector[1]);
routeComp routeCompSouth (r_dinS[`WIDTH_INTERNAL-1], r_dinS[`POS_X_DST], r_dinS[`POS_Y_DST], prodVector[2]);
routeComp routeCompNorth (r_dinN[`WIDTH_INTERNAL-1], r_dinN[`POS_X_DST], r_dinN[`POS_Y_DST], prodVector[3]);
routeComp routeCompLocal (r_dinLocal[`WIDTH_INTERNAL-1], r_dinLocal[`POS_X_DST], r_dinLocal[`POS_Y_DST], prodVector[4]);
routeComp routeCompBypass (r_dinBypass[`WIDTH_INTERNAL-1], r_dinBypass[`POS_X_DST], r_dinBypass[`POS_Y_DST], prodVector[5]);

reg [`WIDTH_INTERNAL_PV-1:0] pipeline_reg1  [0:`NUM_PORT-1];

always @ (posedge clk or negedge reset) begin
   if (~reset) begin
      pipeline_reg1[0] <= 0;
      pipeline_reg1[1] <= 0;
      pipeline_reg1[2] <= 0;
      pipeline_reg1[3] <= 0;
      pipeline_reg1[4] <= 0;
      pipeline_reg1[5] <= 0;
   end
   else begin
      pipeline_reg1[0] <= {prodVector[0],r_dinW};
      pipeline_reg1[1] <= {prodVector[1],r_dinE};
      pipeline_reg1[2] <= {prodVector[2],r_dinS};
      pipeline_reg1[3] <= {prodVector[3],r_dinN};
      pipeline_reg1[4] <= {prodVector[4],r_dinLocal};      
      pipeline_reg1[5] <= {prodVector[5],r_dinBypass};      
   end
end


wire [`WIDTH_INTERNAL_PV-1:0] PNout0, PNout1, PNout2, PNout3;
permutationNetwork permutationNetwork (
pipeline_reg1[0], 
pipeline_reg1[1], 
pipeline_reg1[2], 
pipeline_reg1[3], 
PNout0, 
PNout1, 
PNout2, 
PNout3
);

wire [`NUM_PORT*`WIDTH_PV-1:0] reqVector;
wire [`NUM_PORT*`NUM_PORT-1:0] allocVector;
assign reqVector = {pipeline_reg1[4][`POS_PV],PNout3[`POS_PV],PNout2[`POS_PV],PNout1[`POS_PV],PNout0[`POS_PV],pipeline_reg1[5][`POS_PV]};

portAllocWrapper portAllocWrapper (reqVector, allocVector);

// Strip off PV and valid fields.
// Flit Format pass through Xbar [PktId, FlitId, Time, Xdst, Ydst, payload];
reg [`WIDTH_XBAR-1:0] pipeline_reg2  [0:`NUM_PORT-1];
reg [`NUM_PORT*`NUM_PORT-1:0] pipeline_reg2_allocVector; 

always @ (posedge clk or negedge reset) begin
   if (~reset) begin
      pipeline_reg2[0] <= 0;
      pipeline_reg2[1] <= 0;
      pipeline_reg2[2] <= 0;
      pipeline_reg2[3] <= 0;
      pipeline_reg2[4] <= 0;
      pipeline_reg2[5] <= 0;
      pipeline_reg2_allocVector <= 0;
   end
   else begin
      pipeline_reg2[0] <= PNout0[`WIDTH_XBAR-1:0];
      pipeline_reg2[1] <= PNout1[`WIDTH_XBAR-1:0];
      pipeline_reg2[2] <= PNout2[`WIDTH_XBAR-1:0];
      pipeline_reg2[3] <= PNout3[`WIDTH_XBAR-1:0];
      pipeline_reg2[4] <= pipeline_reg1[4][`WIDTH_XBAR-1:0];
      pipeline_reg2[5] <= pipeline_reg1[5][`WIDTH_XBAR-1:0];
      pipeline_reg2_allocVector <= allocVector;      
   end
end

wire [`WIDTH_XBAR-1:0] XbarOutW, XbarOutE, XbarOutS, XbarOutN, XbarOutLocal, XbarOutBypass;

xbar6Ports xbar6Ports (pipeline_reg2_allocVector, pipeline_reg2[0], pipeline_reg2[1], pipeline_reg2[2], pipeline_reg2[3], pipeline_reg2[4], pipeline_reg2[5], XbarOutW, XbarOutE, XbarOutS, XbarOutN, XbarOutLocal, XbarOutBypass);

reg  [`WIDTH_PORT-1:0] r_doutW, r_doutE, r_doutS, r_doutN;
reg [`WIDTH_PORT-1:0] r_doutLocal, r_doutBypass;
always @ (posedge clk or negedge reset) begin
   if (~reset) begin
      r_doutW <= 0;
      r_doutE <= 0;
      r_doutS <= 0;
      r_doutN <= 0;
      r_doutLocal <= 0;
      r_doutBypass <= 0;
   end
   else begin
      r_doutW <= XbarOutW;
      r_doutE <= XbarOutE;
      r_doutS <= XbarOutS;
      r_doutN <= XbarOutN;
      r_doutLocal <= XbarOutLocal;
      r_doutBypass <= XbarOutBypass;
   end
end

assign doutW = r_doutW;
assign doutE = r_doutE;
assign doutS = r_doutS;
assign doutN = r_doutN;
assign doutLocal = r_doutLocal;
assign doutBypass = r_doutBypass;

endmodule