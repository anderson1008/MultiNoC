// local eject, kill, inject

`include "global.v"

module local(allocVector, validVector1, pipeline_reg1_0,pipeline_reg1_1,pipeline_reg1_2,pipeline_reg1_3, dinBypass, dinLocal, PVLocal, PVBypass, XbarPktIn0, XbarPktIn1, XbarPktIn2, XbarPktIn3, XbarPktIn4, XbarPVIn, localOut, PVBypassOut);

input [`WIDTH_PV-1:0] validVector1, PVLocal, PVBypass;
input [`NUM_CHANNEL*`NUM_PORT-1:0] allocVector;
input [`WIDTH_INTERNAL_PV-1:0] pipeline_reg1_0,pipeline_reg1_1,pipeline_reg1_2,pipeline_reg1_3;
input [`WIDTH_PORT-1:0] dinBypass, dinLocal;
output [`WIDTH_PORT-1:0] XbarPktIn0, XbarPktIn1, XbarPktIn2, XbarPktIn3, XbarPktIn4, localOut;
output [`NUM_CHANNEL*`WIDTH_PV-1:0] XbarPVIn;
output [`WIDTH_PV-1:0] PVBypassOut;

wire [`NUM_CHANNEL-1:0] localVector;
wire [`NUM_CHANNEL-1:0] newAllocVector [0:`NUM_CHANNEL-1];
genvar i;
generate 
   for (i=0; i<`NUM_CHANNEL; i=i+1) begin : reformPV
      assign localVector [i] = allocVector[`NUM_PORT*(i+1)-2]; // showing all local-destined flits.
      assign newAllocVector[i] = {allocVector[`NUM_PORT*(i+1)-1],allocVector[`NUM_PORT*i+:4]}; // exclude local port
   end
endgenerate

// Local Eject
ejector ejector (localVector, pipeline_reg1_0[`WIDTH_PORT-1:0], pipeline_reg1_1[`WIDTH_PORT-1:0], pipeline_reg1_2[`WIDTH_PORT-1:0], pipeline_reg1_3[`WIDTH_PORT-1:0], dinBypass, localOut);

// Eject kill and select channel to inject local flit.
wire [`WIDTH_PV-1:0] validVector2, injectVector;
assign validVector2 = validVector1 ^ localVector; // unset the valid bit of the local destined flit.
ejectKillNInject ejectKillNInject (validVector2, injectVector);

// Allocate port for Local Flit
// Happen after reforming the PV, in parallel with the eject process.
wire [`NUM_CHANNEL-1:0] APV, APVOut, LPV, ALPV, ALPVOut; // availablePV and localPV
assign APV = ~(newAllocVector[0] | newAllocVector[1] | newAllocVector[2] | newAllocVector[3] | newAllocVector[4]);
highestBit highestBitAPV (APV, APVOut);
highestBit highestBitLPV (ALPV, ALPVOut);
assign ALPV =  PVLocal & APV;
assign LPV = |ALPV ? ALPVOut : APVOut;

// Inject
wire [`WIDTH_PORT-1:0] XbarPktIn [0:`NUM_CHANNEL-1];

assign XbarPktIn0 = injectVector[0] ? dinLocal : pipeline_reg1_0[`WIDTH_PORT-1:0];
assign XbarPktIn1 = injectVector[1] ? dinLocal : pipeline_reg1_1[`WIDTH_PORT-1:0];
assign XbarPktIn2 = injectVector[2] ? dinLocal : pipeline_reg1_2[`WIDTH_PORT-1:0];
assign XbarPktIn3 = injectVector[3] ? dinLocal : pipeline_reg1_3[`WIDTH_PORT-1:0];
assign XbarPktIn4 = injectVector[4] ? dinLocal : dinBypass;

assign XbarPVIn[4:0] = injectVector[0] ? LPV : newAllocVector[0];
assign XbarPVIn[9:5] = injectVector[1] ? LPV : newAllocVector[1];
assign XbarPVIn[14:10] = injectVector[2] ? LPV : newAllocVector[2];
assign XbarPVIn[19:15] = injectVector[3] ? LPV : newAllocVector[3];
assign XbarPVIn[24:20] = injectVector[4] ? LPV : newAllocVector[4];

// forward PV of bypass flit
reg [`WIDTH_PORT-1:0] r_PVBypassOut;
always @ * begin
   if (XbarPVIn[4]) r_PVBypassOut <= pipeline_reg1_0[`POS_PV];
   else if (XbarPVIn[9]) r_PVBypassOut <= pipeline_reg1_1[`POS_PV];
   else if (XbarPVIn[14]) r_PVBypassOut <= pipeline_reg1_2[`POS_PV];
   else if (XbarPVIn[19]) r_PVBypassOut <= pipeline_reg1_3[`POS_PV];
   else if (XbarPVIn[24]) begin
      if (injectVector[4]) r_PVBypassOut <= PVLocal;
      else r_PVBypassOut <= PVBypass;
   end
   else
      r_PVBypassOut <= 0;
end

assign PVBypassOut = r_PVBypassOut;

endmodule