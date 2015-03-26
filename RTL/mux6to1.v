// 6to1 mux

/*
   sel   out
   000   ina
   001   inb
   010   inc
   011   ind
   1x0   ine
   1x1   inf
*/

module mux6to1 (ina, inb, inc, ind, ine, inf, sel, out);

input ina, inb, inc, ind, ine, inf;
input [2:0] sel;
output out;

wire temp1, temp2, temp3, temp4;

mux2to1 mux11 (ina, inb, sel[0], temp1);
mux2to1 mux12 (inc, ind, sel[0], temp2);
mux2to1 mux13 (ine, inf, sel[0], temp3);
mux2to1 mux21 (temp1, temp2, sel[1], temp4);
mux2to1 mux31 (temp4, temp3, sel[2], out);

endmodule