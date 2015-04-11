// parallel port allocator

`include "global.v"

module portAllocParallel (PVIn, validVector, PVOut);

input [`NUM_CHANNEL*`WIDTH_PV-1:0] PVIn; // there are 5 flits on channels.
input [`NUM_CHANNEL-1:0] validVector;
output [`NUM_CHANNEL*`NUM_PORT-1:0] PVOut;   // there are 6 candidate outport.


wire [`WIDTH_PV-1:0] PVprime [0:`NUM_CHANNEL-1]; // split input PV
wire [`NUM_CHANNEL-1:0] PV [0:`NUM_CHANNEL-1];

genvar i;
generate
   for (i=0; i<`NUM_CHANNEL; i=i+1) begin : bitVectorFilter
      assign PVprime[i] = PVIn[i*`WIDTH_PV+:`WIDTH_PV];
      highestBit fliter (PVprime[i], PV[i]);
   end
endgenerate

// ----------------------------------------------------------------- //
// Compute
// APV: all Available Ports Vector
// APVi: the available port vector for flit i;
wire [`NUM_CHANNEL-1:0] APV;
wire [`NUM_CHANNEL-1:0] APVi [1:4];
assign APVi[1] = ~ PV[0];
assign APVi[2] = ~ (PV[0]|PV[1]);
assign APVi[3] = ~ (PV[0]|PV[1]|PV[2]);
assign APVi[4] = ~ (PV[0]|PV[1]|PV[2]|PV[3]);
assign APV =  ~ (PV[0]|PV[1]|PV[2]|PV[3]|PV[4]);
// ----------------------------------------------------------------- //

// ----------------------------------------------------------------- //
// Compute the non-conflicted port vector for each flit.
// Also, based on the port demand of each flits, all avilable ports are known.
// So, the frist, second, and last available port is also known.
wire [3:0] APVFirst, APVSecond, APVLast;
wire [`NUM_CHANNEL-1:0] PPVi [1:4];
wire                PPVExist [1:4];
firstbit firstAvailablePort (APV[3:0], APVFirst);
secondHighestBit secondAvailablePort (APV[3:0], APVSecond);
lastBit LastAvailablePort (APV[3:0], APVLast);
generate
   for (i=1; i<=4; i=i+1) begin : computePPV
      computePPV computePPV(PV[i], APVi[i], PPVExist[i], PPVi[i]);
   end
endgenerate
// ----------------------------------------------------------------- //


// ----------------------------------------------------------------- //
parameter BYPASS = 6'b100000; 

reg [`NUM_PORT-1:0] FPV [0:4];
always @ * begin
   if (validVector[0]) FPV[0] <= {1'b0,PV[0]};
   else FPV[0] <= 0;
   
   if (validVector[1]) begin
      if (PPVExist[1])
         FPV[1] <= {1'b0,PPVi[1]};
      else
         FPV[1] <= BYPASS;
   end
   else
      FPV[1] <= 0;

   if (validVector[2]) begin
      if (PPVExist[2])
         FPV[2] <= {1'b0,PPVi[2]};
      else if (PPVExist[1])
         FPV[2] <= BYPASS;
      else
         FPV[2] <= {2'b0,APVFirst};
   end
   else
      FPV[2] <= 0;

   if (validVector[3]) begin
      if (PPVExist[3])
         FPV[3] <= {1'b0,PPVi[3]};
      else if (PPVExist[1] & PPVExist[2])
         FPV[3] <= BYPASS;
      else if (PPVExist[1] ^ PPVExist[2])
         FPV[3] <= {2'b0,APVFirst};
      else
         FPV[3] <= {2'b0,APVSecond};
   end
   else
      FPV[3] <= 0;
      
   if (validVector[4]) begin
      if (PPVExist[4])
         FPV[4] <= {1'b0,PPVi[4]};
      else if (BYPASS)
         FPV[4] <= BYPASS;
      else
         FPV[4] <= {2'b0,APVLast};
   end
   else
      FPV[4] <= 0;
end

/*
wire [`NUM_PORT-1:0] FPV [0:4]; // Final PV for each of flits
assign FPV[0] = validVector[0] ? {1'b0,PV[0]} : 0;
assign FPV[1] = validVector[1] ? (PPVExist[1] ? {1'b0,PPVi[1]} : BYPASS) : 0;
assign FPV[2] = validVector[2] ? (
                                    PPVExist[2] ? {1'b0,PPVi[2]} : 
                                    (PPVExist[1] ? BYPASS : {2'b0,APVFirst})
                                 ) : 0;
wire [`NUM_PORT-1:0] temp [2:0];
assign temp[0] = PPVExist[1] ? {2'b0,APVFirst} : {2'b0,APVSecond};
assign temp[1] = PPVExist[1] ? BYPASS : {2'b0,APVFirst};
assign temp[2] = PPVExist[2] ? temp[1] : temp[0];
assign FPV[3] = validVector[3] ? (PPVExist[3] ? {1'b0,PPVi[3]} : temp[2]) : 0;
wire allExist;
assign allExist = PPVExist[1]&&PPVExist[2]&&PPVExist[3];
assign FPV[4] = validVector[4] ? (PPVExist[4] ? {1'b0,PPVi[4]} : (allExist ? BYPASS : {2'b0,APVLast})) : 0;
*/
// ----------------------------------------------------------------- //




generate
   for (i=0; i<`NUM_CHANNEL; i=i+1) begin : aggregate
      assign PVOut [i*`NUM_PORT+:`NUM_PORT] = FPV[i];
   end
endgenerate

endmodule