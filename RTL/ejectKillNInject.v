// ejectKill and Inject

`include "global.v"

module ejectKillNInject (validIn, localInjectGrant);

input [`NUM_CHANNEL-1:0] validIn;
output [`NUM_CHANNEL-1:0] localInjectGrant;

assign localInjectGrant[0] = ~validIn[0];
assign localInjectGrant[1] = validIn[0] & ~validIn[1];
assign localInjectGrant[2] = validIn[0] & validIn[1] & ~validIn[2];
assign localInjectGrant[3] = validIn[0] & validIn[1] & validIn[2]& ~validIn[3];
assign localInjectGrant[4] = validIn[0] & validIn[1] & validIn[2]& validIn[3] & ~validIn[4];

endmodule