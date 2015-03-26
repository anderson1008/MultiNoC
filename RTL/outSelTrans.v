// translate the port allocation result to outSel signals

`include "global.v"

module outSelTrans (alloc, outSel);

input [`NUM_PORT-1:0] alloc;
output reg [`LOG_NUM_PORT-1:0] outSel;


always @ * begin
   casex (alloc)
      `NUM_PORT'b1xxxxx: 
         outSel <= `LOG_NUM_PORT'd5;
      `NUM_PORT'b01xxxx: 
         outSel <= `LOG_NUM_PORT'd4;
      `NUM_PORT'b001xxx: 
         outSel <= `LOG_NUM_PORT'd3;
      `NUM_PORT'b0001xx: 
         outSel <= `LOG_NUM_PORT'd2;
      `NUM_PORT'b00001x: 
         outSel <= `LOG_NUM_PORT'd1;
      `NUM_PORT'b000001: 
         outSel <= `LOG_NUM_PORT'd0;          
      default:
         outSel <= `LOG_NUM_PORT'd0;   
   endcase
end

endmodule
