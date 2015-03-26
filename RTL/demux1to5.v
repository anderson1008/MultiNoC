// demux 1 to 5

module demux1to5 (din, sel, out1, out2, out3, out4, out5);

input din;
input [2:0] sel;
output out1, out2, out3, out4, out5;

/*
   sel   din
   000   out1
   001   out2
   010   out3
   011   out4
   100   out5
*/

wire temp [2:0];

demux1to2 demux11(din, sel[0], temp[0], temp[1]);
demux1to2 demux21(temp[0], sel[1], temp[2], out3);
demux1to2 demux22(temp[1], sel[1], out2, out4);
demux1to2 demux31(temp[2], sel[2], out1, out5);

endmodule