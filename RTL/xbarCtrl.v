// Xbar Control

`include "global.v"

module xbarCtrl (allocVector, outSelVector, inSelVector);

input [`NUM_PORT*`NUM_PORT-1:0] allocVector;

output [`NUM_PORT*`LOG_NUM_PORT-1:0] outSelVector, inSelVector;

wire [`NUM_PORT-1:0] alloc [`NUM_PORT-1:0];
wire  [`LOG_NUM_PORT-1:0] outSel [0:`NUM_PORT-1]; // 4-LOCAL; 3-N; 2-S; 1-E; 0-W;
reg  [`LOG_NUM_PORT-1:0] inSel [0:`NUM_PORT-1]; // 4-LOCAL; 3-N; 2-S; 1-E; 0-W;

genvar j;
generate 
   for (j=0; j<`NUM_PORT; j=j+1) begin : outSelTranslate
      assign alloc[j] = allocVector [j*`NUM_PORT+:`NUM_PORT];
      outSelTrans outSelTranslation(alloc[j], outSel[j]);
   end
endgenerate

integer k;
initial 
   for (k=0; k<`NUM_PORT; k=k+1) 
      inSel[k] = `LOG_NUM_PORT'd0;
   
always @ * begin
  
   case (outSel[5])
      0: inSel[0] <= 5;
      1: inSel[1] <= 5;
      2: inSel[2] <= 5;
      3: inSel[3] <= 5;
      4: inSel[4] <= 5;    
      5: inSel[5] <= 5;    
   endcase

   case (outSel[4])
      0: inSel[0] <= 4;
      1: inSel[1] <= 4;
      2: inSel[2] <= 4;
      3: inSel[3] <= 4;
      4: inSel[4] <= 4;    
      5: inSel[5] <= 4;    
   endcase  
   
   case (outSel[3])
      0: inSel[0] <= 3;
      1: inSel[1] <= 3;
      2: inSel[2] <= 3;
      3: inSel[3] <= 3;
      4: inSel[4] <= 3;
      5: inSel[5] <= 3;         
   endcase
   
   case (outSel[2])
      0: inSel[0] <= 2;
      1: inSel[1] <= 2;
      2: inSel[2] <= 2;
      3: inSel[3] <= 2;
      4: inSel[4] <= 2;
      5: inSel[5] <= 2;
   endcase

   case (outSel[1])
      0: inSel[0] <= 1;
      1: inSel[1] <= 1;
      2: inSel[2] <= 1;
      3: inSel[3] <= 1;
      4: inSel[4] <= 1;
      5: inSel[5] <= 1;
   endcase
   
   case (outSel[0])
      0: inSel[0] <= 0;
      1: inSel[1] <= 0;
      2: inSel[2] <= 0;
      3: inSel[3] <= 0;
      4: inSel[4] <= 0;
      5: inSel[5] <= 0;
   endcase   
end





/*
reg i = 0;

always @ * begin
   for (i = 0; i < `NUM_PORT; i=i+1) begin
      case (alloc[i])
         `NUM_PORT'b1xxxx: begin
               outSel[i] <= 4;
               inSel[4] <= i;
            end
         `NUM_PORT'b01xxx: begin
               outSel[i] <= 3;
               inSel[3] <= i;
            end
         `NUM_PORT'b001xx: begin
               outSel[i] <= 2;
               inSel[2] <= i;
            end
         `NUM_PORT'b0001x: begin
               outSel[i] <= 1;
               inSel[1] <= i;
            end
         `NUM_PORT'b00001: begin
               outSel[i] <= 0;
               inSel[0] <= i;
            end
      endcase
   end
end
*/

generate 
   for (j=0; j<`NUM_PORT; j=j+1) begin : mergeOutput
      assign outSelVector[j*`LOG_NUM_PORT+:`LOG_NUM_PORT] = outSel[j];
      assign inSelVector[j*`LOG_NUM_PORT+:`LOG_NUM_PORT] = inSel[j];
   end
endgenerate

/*
always @ * begin
   case (alloc)
      `NUM_PORT'b1xxxx: begin
            outSel[4] <= `LOG_NUM_PORT'd4;
            inSel[4] <= `LOG_NUM_PORT'd4;
         end
      `NUM_PORT'b01xxx: begin
            outSel[4] <= `LOG_NUM_PORT'd3;
            inSel[3] <= `LOG_NUM_PORT'd4;
         end
      `NUM_PORT'b001xx: begin
            outSel[4] <= `LOG_NUM_PORT'd2;
            inSel[2] <= `LOG_NUM_PORT'd4;
         end
      `NUM_PORT'b0001x: begin
            outSel[4] <= `LOG_NUM_PORT'd1;
            inSel[1] <= `LOG_NUM_PORT'd4;
         end
      `NUM_PORT'b00001: begin
            outSel[4] <= `LOG_NUM_PORT'd0;
            inSel[0] <= `LOG_NUM_PORT'd4;
         end
   endcase
end
*/


endmodule