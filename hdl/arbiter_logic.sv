/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : arbiter_logic.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: 2021年06月22日 星期二 10时44分46秒
 ************************************************************************/
module arbiter_logic(
   input  wire            arbiterEnable   ,
   input  wire            discOutLocal    ,
   input  wire   [3:0]    discOutNeighbour ,
   output wire   [3:0]    ackToNeighbour  ,

   input  wire   [3:0]    ackFromNeighbour,
   output wire            winerAll
);
   wire [3:0]  ackForLocal;

   arbiterCell compareWithRight ( .req({discOutLocal,discOutNeighbour[0]}),  .ack({ackForLocal[0],ackToNeighbour[0]}));
   arbiterCell compareWithBR    ( .req({discOutLocal,discOutNeighbour[1]}),  .ack({ackForLocal[1],ackToNeighbour[1]}));
   arbiterCell compareWithBot   ( .req({discOutLocal,discOutNeighbour[2]}),  .ack({ackForLocal[2],ackToNeighbour[2]}));
   arbiterCell compareWithBL    ( .req({discOutLocal,discOutNeighbour[3]}),  .ack({ackForLocal[3],ackToNeighbour[3]}));

   assign winerAll = arbiterEnable ? ((&ackFromNeighbour) & (~|ackToNeighbour)) : discOutLocal; 
endmodule 
