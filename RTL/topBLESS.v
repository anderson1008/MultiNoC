// Top wrapper of baseline BLESS router with Look Ahead Routing

`include "global.v"

module topBLESS (clk, reset, dinW, dinE, dinS, dinN, dinLocal, dinBypass, PVBypass, PVLocal, doutW, doutE, doutS, doutN, doutLocal, doutBypass, PVBypassOut);

input clk, reset;
input [`WIDTH_PORT-1:0] dinW, dinE, dinS, dinN;
input [`WIDTH_PORT-1:0] dinLocal, dinBypass;
input [`WIDTH_PV-1:0]   PVBypass, PVLocal;

output [`WIDTH_PORT-1:0] doutW, doutE, doutS, doutN;
output [`WIDTH_PORT-1:0]  doutLocal, doutBypass;
output [`WIDTH_PV-1:0]  PVBypassOut;

reg [`WIDTH_INTERNAL-1:0] r_dinW, r_dinE, r_dinS, r_dinN;
reg [`WIDTH_INTERNAL-1:0] r_dinLocal, r_dinBypass;
reg [`WIDTH_PV-1:0] r_PVBypass, r_PVLocal;

genvar i;

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

      if (dinBypass != 0) // bypass channel is latched at the input.
         r_dinBypass <= {1'b1,dinBypass};
      else
         r_dinBypass <= 0;
         
      if (PVBypass != 0)
         r_PVBypass <= PVBypass;
      else
         r_PVBypass <= 0;
         
      if (PVBypass != 0)
         r_PVLocal <= PVLocal;
      else
         r_PVLocal <= 0;
   end
end

wire [`WIDTH_PV-1:0] prodVector [0:3];
routeComp routeCompWest (r_dinW[`WIDTH_INTERNAL-1], r_dinW[`POS_X_DST], r_dinW[`POS_Y_DST], prodVector[0]);
routeComp routeCompEast (r_dinE[`WIDTH_INTERNAL-1], r_dinE[`POS_X_DST], r_dinE[`POS_Y_DST], prodVector[1]);
routeComp routeCompSouth (r_dinS[`WIDTH_INTERNAL-1], r_dinS[`POS_X_DST], r_dinS[`POS_Y_DST], prodVector[2]);
routeComp routeCompNorth (r_dinN[`WIDTH_INTERNAL-1], r_dinN[`POS_X_DST], r_dinN[`POS_Y_DST], prodVector[3]);

wire [`WIDTH_INTERNAL_PV-1:0] PNin  [0:`NUM_PORT-3];
assign PNin[0] = {prodVector[0],r_dinW};
assign PNin[1] = {prodVector[1],r_dinE};
assign PNin[2] = {prodVector[2],r_dinS};
assign PNin[3] = {prodVector[3],r_dinN};

wire [`WIDTH_INTERNAL_PV-1:0] PNout0, PNout1, PNout2, PNout3;
permutationNetwork permutationNetwork ( PNin[0], PNin[1], PNin[2], PNin[3], PNout0, PNout1, PNout2, PNout3);

reg [`WIDTH_INTERNAL_PV-1:0] pipeline_reg1  [0:3];

always @ (posedge clk or negedge reset) begin
   if (~reset) begin
      pipeline_reg1[0] <= 0;
      pipeline_reg1[1] <= 0;
      pipeline_reg1[2] <= 0;
      pipeline_reg1[3] <= 0;
   end
   else begin
      pipeline_reg1[0] <= PNout0;
      pipeline_reg1[1] <= PNout1;
      pipeline_reg1[2] <= PNout2;
      pipeline_reg1[3] <= PNout3;   
   end
end
// ----------------------------------------------------------------- //
//                 Pipeline Stage 2 - PA + XT;
// ----------------------------------------------------------------- //

// Port Allocation
wire [`NUM_CHANNEL*`WIDTH_PV-1:0] reqVector;
wire [`NUM_CHANNEL*`NUM_PORT-1:0] allocVector;
assign reqVector = {r_PVBypass,pipeline_reg1[3][`POS_PV],pipeline_reg1[2][`POS_PV],pipeline_reg1[1][`POS_PV],pipeline_reg1[0][`POS_PV]};
wire [`NUM_CHANNEL-1:0] validVector1;
assign validVector1 = {r_dinBypass[`POS_VALID],pipeline_reg1[3][`POS_VALID],pipeline_reg1[2][`POS_VALID],pipeline_reg1[1][`POS_VALID],pipeline_reg1[0][`POS_VALID]};
portAllocParallel portAllocParallel (reqVector, validVector1, allocVector);

// Must reform allocated PV since local port is not an option..
// Starting from here, newAllocVector[4] is the bypassed port
wire [`WIDTH_PORT-1:0] localOut;

wire [`WIDTH_PORT-1:0] XbarPktIn [0:`NUM_CHANNEL-1];
wire [`NUM_CHANNEL*`WIDTH_PV-1:0] XbarPVIn;

local local (allocVector, validVector1, pipeline_reg1[0],pipeline_reg1[1],pipeline_reg1[2],pipeline_reg1[3], r_dinBypass[`WIDTH_PORT-1:0], r_dinLocal[`WIDTH_PORT-1:0], r_PVLocal, r_PVBypass, XbarPktIn[0], XbarPktIn[1], XbarPktIn[2], XbarPktIn[3], XbarPktIn[4], XbarPVIn, localOut, PVBypassOut);

/*
wire [`NUM_CHANNEL-1:0] localVector;
wire [`NUM_CHANNEL-1:0] newAllocVector [0:`NUM_CHANNEL-1];

generate 
   for (i=0; i<`NUM_CHANNEL; i=i+1) begin : reformPV
      assign localVector [i] = allocVector[`NUM_PORT*(i+1)-2]; // showing all local-destined flits.
      assign newAllocVector[i] = {allocVector[`NUM_PORT*(i+1)-1],allocVector[`NUM_PORT*i+:4]}; // exclude local port
   end
endgenerate


// Local Eject
ejector ejector (localVector, pipeline_reg1[0][`WIDTH_PORT-1:0], pipeline_reg1[1][`WIDTH_PORT-1:0], pipeline_reg1[2][`WIDTH_PORT-1:0], pipeline_reg1[3][`WIDTH_PORT-1:0], r_dinBypass[`WIDTH_PORT-1:0], localOut);

// Eject kill and select channel to inject local flit.
wire [`NUM_CHANNEL-1:0] validVector2, injectVector;
assign validVector2 = validVector1 ^ localVector; // unset the valid bit of the local destined flit.
ejectKillNInject ejectKillNInject (validVector2, injectVector);

// Allocate port for Local Flit
// Happen after reforming the PV, in parallel with the eject process.
wire [`NUM_CHANNEL-1:0] APV, APVOut, LPV, ALPV, ALPVOut; // availablePV and localPV
assign APV = ~(newAllocVector[0] | newAllocVector[1] | newAllocVector[2] | newAllocVector[3] | newAllocVector[4]);
highestBit highestBitAPV (APV, APVOut);
highestBit highestBitLPV (ALPV, ALPVOut);
assign ALPV =  r_PVLocal & APV;
assign LPV = |ALPV ? ALPVOut : APVOut;

// Inject
wire [`WIDTH_PORT-1:0] XbarPktIn [0:`NUM_CHANNEL-1];
wire [`NUM_CHANNEL*`NUM_CHANNEL-1:0] XbarPVIn;
generate 
   for (i=0; i<`NUM_CHANNEL-1; i=i+1) begin : Inject
      assign XbarPktIn[i] = injectVector[i] ? r_dinLocal[`WIDTH_PORT-1:0] : pipeline_reg1[i][`WIDTH_PORT-1:0];
      assign XbarPVIn[i*`NUM_CHANNEL+:`NUM_CHANNEL] = injectVector[i] ? LPV : newAllocVector[i];
   end
endgenerate
assign XbarPktIn[4] = injectVector[4] ? r_dinLocal[`WIDTH_PORT-1:0] : r_dinBypass[`WIDTH_PORT-1:0];
assign XbarPVIn[4*`NUM_CHANNEL+:`NUM_CHANNEL] = injectVector[4] ? LPV : newAllocVector[4];

// forward PV of bypass flit
reg [`WIDTH_PV-1:0] r_PVBypassOut;
always @ * begin
   if (XbarPVIn[4]) r_PVBypassOut <= pipeline_reg1[0][`POS_PV];
   else if (XbarPVIn[9]) r_PVBypassOut <= pipeline_reg1[1][`POS_PV];
   else if (XbarPVIn[14]) r_PVBypassOut <= pipeline_reg1[2][`POS_PV];
   else if (XbarPVIn[19]) r_PVBypassOut <= pipeline_reg1[3][`POS_PV];
   else if (XbarPVIn[24]) begin
      if (injectVector[4]) r_PVBypassOut <= r_PVLocal;
      else r_PVBypassOut <= r_PVBypass;
   end
   else
      r_PVBypassOut <= 0;
end
*/

// Switch Traversal
wire [`WIDTH_PORT-1:0] XbarOutW, XbarOutE, XbarOutS, XbarOutN, XbarOutBypass;
Xbar5Ports Xbar5Ports (XbarPVIn, XbarPktIn[0], XbarPktIn[1], XbarPktIn[2], XbarPktIn[3], XbarPktIn[4], XbarOutW, XbarOutE, XbarOutS, XbarOutN, XbarOutBypass);



reg  [`WIDTH_PORT-1:0] r_doutW, r_doutE, r_doutS, r_doutN;
reg [`WIDTH_PORT-1:0] r_doutLocal;
always @ (posedge clk or negedge reset) begin
   if (~reset) begin
      r_doutW <= 0;
      r_doutE <= 0;
      r_doutS <= 0;
      r_doutN <= 0;
      r_doutLocal <= 0;
   end
   else begin
      r_doutW <= XbarOutW;
      r_doutE <= XbarOutE;
      r_doutS <= XbarOutS;
      r_doutN <= XbarOutN;
      r_doutLocal <= localOut;
   end
end

assign doutW = r_doutW;
assign doutE = r_doutE;
assign doutS = r_doutS;
assign doutN = r_doutN;
assign doutLocal = r_doutLocal;
assign doutBypass = XbarOutBypass; // bypassed flit is only latched at the input.
//assign PVBypassOut = r_PVBypassOut;

endmodule