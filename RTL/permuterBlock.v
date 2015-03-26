// Permuter Block

`include "global.v"

module permuterBlock (inFlit0, inFlit1, swap, outFlit0, outFlit1);

input                            swap;
input		[`WIDTH_INTERNAL_PV-1:0] 	inFlit0,inFlit1;
output 	[`WIDTH_INTERNAL_PV-1:0]	outFlit0, outFlit1;

wire	[`WIDTH_INTERNAL_PV-1:0] swapFlit [1:0];
wire	[`WIDTH_INTERNAL_PV-1:0] straightFlit [1:0];

demuxWrapper1to2 demux0(
	.din			   (inFlit0), 
	.sel				(swap), 
	.out1				(straightFlit[0]), 
	.out2				(swapFlit[0])
);
	
demuxWrapper1to2 demux1(
	.din			   (inFlit1), 
	.sel				(swap), 
	.out1				(straightFlit[1]), 
	.out2				(swapFlit[1])
);

muxWrapper2to1 mux0(
	.ina				(straightFlit[0]), 
	.inb				(swapFlit[1]), 
	.sel				(swap), 
	.out			   (outFlit0)
);
	
muxWrapper2to1 mux1(
	.ina				(straightFlit[1]), 
	.inb				(swapFlit[0]), 
	.sel				(swap), 
	.out			   (outFlit1)
);
	
endmodule
