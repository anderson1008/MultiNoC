// mux 5to1

module mux5to1 (ina, inb, inc, ind, ine, sel, out);

input ina, inb, inc, ind, ine;
input [2:0] sel;
output out;
/*
   sel   out
   000   ina
   001   inb
   010   inc
   011   ind
   1xx   ine
*/

wire temp1, temp2, temp3;

mux2to1 mux11 (ina, inb, sel[0], temp1);
mux2to1 mux12 (inc, ind, sel[0], temp2);
mux2to1 mux21 (temp1, temp2, sel[1], temp3);
mux2to1 mux31 (temp3, ine, sel[2], out);

endmodule