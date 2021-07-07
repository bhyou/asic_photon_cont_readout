/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : syncronization.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: 2021年06月22日 星期二 10时58分38秒
 ************************************************************************/
module syncronization(
   input  wire          discOutSumLocal    ,
   input  wire [2:0]    discOutSumNeighbour,
   input  wire          sync_enable        ,
   input  wire          winerAll           ,
   output wire          sumPulse
);

   wire   overThreshold = discOutSumLocal & (&discOutSumNeighbour);
   assign sumPulse = sync_enable ? (winerAll & overThreshold) : discOutSumLocal; 

endmodule 
