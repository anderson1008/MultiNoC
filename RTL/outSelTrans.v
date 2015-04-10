// translate the port allocation result to outSel signals

`include "global.v"

module outSelTrans (alloc, outSel);

input [`NUM_CHANNEL-1:0] alloc;
output reg [`LOG_NUM_PORT-1:0] outSel;


always @ * begin
   casex (alloc)
      `NUM_CHANNEL'b1xxxx: 
         outSel <= `LOG_NUM_PORT'd4;
      `NUM_CHANNEL'b01xxx: 
         outSel <= `LOG_NUM_PORT'd3;
      `NUM_CHANNEL'b001xx: 
         outSel <= `LOG_NUM_PORT'd2;
      `NUM_CHANNEL'b0001x: 
         outSel <= `LOG_NUM_PORT'd1;
      `NUM_CHANNEL'b00001: 
         outSel <= `LOG_NUM_PORT'd0;          
      default:
         outSel <= `LOG_NUM_PORT'd7;   
   endcase
end

endmodule
