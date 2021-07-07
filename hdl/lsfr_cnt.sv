/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : lsfr_cnt.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: 2021年06月22日 星期二 10时10分17秒
 ************************************************************************/
module lsfr_cnt(
   input  wire   shutter   ,
   input  wire    clk_read ,
   input  wire    reset    ,
   input  wire    pulseIn  ,
   input  wire    SerIn    ,
   output wire    SerOut
);

   reg [15:1]  lsfr;

   wire clock = shutter ? clk_read : pulseIn; 
   always@(posedge clock, posedge reset) begin
      if(reset) begin
         lsfr <= '1;
      end
      else begin 
         lsfr[1]  <= shutter ? SerIn : (lsfr[14]^ lsfr[15]);
         lsfr[2]  <= lsfr[1];
         lsfr[3]  <= lsfr[2];
         lsfr[4]  <= lsfr[3];
         lsfr[5]  <= lsfr[4];
         lsfr[6]  <= lsfr[5];
         lsfr[7]  <= lsfr[6];
         lsfr[8]  <= lsfr[7];
         lsfr[9]  <= lsfr[8];
         lsfr[10] <= lsfr[9];
         lsfr[11] <= lsfr[10];
         lsfr[12] <= lsfr[11];
         lsfr[13] <= lsfr[12];
         lsfr[14] <= lsfr[13];
         lsfr[15] <= lsfr[14];
      end
   end

   assign SerOut = lsfr[15];
endmodule
 
