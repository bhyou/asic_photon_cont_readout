/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : digit_front_end.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: 2021年06月22日 星期二 10时43分09秒
 ************************************************************************/
module digit_front_end(
   input  wire          SummingMode     ,

   input  wire   [3:0]  discOutNeighbour ,
   output wire   [3:0]  ackToNeighbour  ,

   input  wire          discOutLocal    ,
   input  wire   [3:0]  ackFromNeighbour,
   output wire          hitPulse        ,

   input  wire          discOutSumLocal    ,
   input  wire   [2:0]  discOutSumNeighbour,
   output wire          sumPulse           ,

   input  wire          clk_read ,
   input  wire          reset    ,
   input  wire          shutterA ,
   input  wire          shutterB ,
   input  wire          SerInA   ,
   input  wire          SerInB   ,
   output wire          SerOutA  ,
   output wire          SerOutB 
);

arbiter_logic  inst_arbiter(
   .arbiterEnable    ( SummingMode     ),
   .discOutLocal     ( discOutLocal    ),
   .discOutNeighbour ( discOutNeighbour ),
   .ackToNeighbour   ( ackToNeighbour  ),
   .ackFromNeighbour ( ackFromNeighbour),
   .winerAll         ( hitPulse        )
);

lsfr_cnt    Cnter0(
   .shutter  (shutterA) ,
   .clk_read (clk_read) ,
   .reset    (reset   ) ,
   .pulseIn  (hitPulse) ,
   .SerIn    (SerInA) ,
   .SerOut   (SerOutA)
);

syncronization inst_sync(
   .discOutSumLocal     ( discOutSumLocal     ),
   .discOutSumNeighbour ( discOutSumNeighbour ),
   .sync_enable         ( SummingMode    ),
   .winerAll            ( hitPulse       ),
   .sumPulse            ( sumPulse       ) 
);

lsfr_cnt    Cnter1(
   .shutter  (shutterB) ,
   .clk_read (clk_read) ,
   .reset    (reset   ) ,
   .pulseIn  (sumPulse) ,
   .SerIn    (SerInB  ) ,
   .SerOut   (SerOutB)
);

endmodule 
