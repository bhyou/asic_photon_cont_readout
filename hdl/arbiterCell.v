/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : arbiter.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Fri 11 Jun 2021 04:27:27 PM CST
 ************************************************************************/
module arbiterCell(
   input   [1:0]  req,
   output  [1:0]  ack
);

   wire  Q, P;

   assign Q = ~(P & req[0]);
   assign P = ~(Q & req[1]);

   wire gnd = 1'b0; 
   pmos T1 (ack[1], Q,   P);  // out(Drain) in(Source) in(Gate)
   nmos T2 (ack[1], 1'b0,P);  // out(Drain) in(Source) in(Gate)

   pmos T3 (ack[0], P,   Q);
   nmos T4 (ack[0], 1'b0,Q);
endmodule
 
module inv_mos(
   input  wire  I,
   output wire ZN
);
   nmos MOS1 (ZN, 1'b0, I);
   pmos MOS2 (ZN, 1'b1, I);

endmodule 
