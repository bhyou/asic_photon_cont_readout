/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : lsfr_driver.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Thu 24 Jun 2021 04:18:21 PM CST
 ************************************************************************/
module lsfr_driver(

   input  wire        clk_read,
   input  wire        shift_in,
   input  wire        shift_en,
   input  wire        reset   ,
   output reg  [14:0] binOut  
);
   reg [14:0]   sfReg;  
   reg [15:1]   seed;

   always@(posedge clk_receive, posedge reset) begin 
      if(reset) begin
         seed <= '1;
      end
      else begin
         seed[1]  <= start ? (seed[14]^seed[15]) : seed[1] ; 
         seed[2]  <= start ? (seed[1] ) : seed[2] ; 
         seed[3]  <= start ? (seed[2] ) : seed[3] ; 
         seed[4]  <= start ? (seed[3] ) : seed[4] ; 
         seed[5]  <= start ? (seed[4] ) : seed[5] ; 
         seed[6]  <= start ? (seed[5] ) : seed[6] ; 
         seed[7]  <= start ? (seed[6] ) : seed[7] ; 
         seed[8]  <= start ? (seed[7] ) : seed[8] ; 
         seed[9]  <= start ? (seed[8] ) : seed[9] ; 
         seed[10] <= start ? (seed[9] ) : seed[10]; 
         seed[11] <= start ? (seed[10]) : seed[11]; 
         seed[12] <= start ? (seed[11]) : seed[12]; 
         seed[13] <= start ? (seed[12]) : seed[13]; 
         seed[14] <= start ? (seed[13]) : seed[14]; 
         seed[15] <= start ? (seed[14]) : seed[15]; 
      end                              
   end

   always_ff @( posedge clk_receive, posedge reset) begin : shift_register
      if (reset) begin
         sfReg <= '0;
      end
      else begin           
         sfReg <= {sfReg[13:0],shift_in};
      end
   end
endmodule
