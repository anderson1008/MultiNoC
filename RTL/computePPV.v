// prefered productive vector computation

`include "global.v"

module computePPV (PVi, APVi, PPVExist, PPV);
input [4:0] PVi, APVi;
output [4:0] PPV;
output PPVExist;

assign PPV = APVi & PVi;
assign PPVExist = |PPV;  // unary OR


endmodule