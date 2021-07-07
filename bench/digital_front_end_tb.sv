/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : digital_front_end_tb.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: 2021年06月22日 星期二 14时38分56秒
 ************************************************************************/
module digital_front_end_tb;

   reg            SummingMode     ;

   reg     [3:0]  discOutNeighbour ;
   wire    [3:0]  ackToNeighbour  ;

   reg            discOutLocal    ;
   reg     [3:0]  ackFromNeighbour;
   wire           hitPulse          ;

   reg            discOutSumLocal    ;
   reg     [2:0]  discOutSumNeighbour;
   wire           sumPulse           ;

   reg            clk_read ;
   reg            reset    ;
   reg            shutter  ;
   reg            SerInA   ;
   reg            SerInB   ;
   wire           SerOutA  ;
   wire           SerOutB  ;

   digit_front_end u_digFrontEnd(
      .SummingMode        (SummingMode     ),
      .discOutNeighbour   (discOutNeighbour ),
      .ackToNeighbour     (ackToNeighbour  ),
      .discOutLocal       (discOutLocal    ),
      .ackFromNeighbour   (ackFromNeighbour),
      .hitPulse           (hitPulse        ),
      .discOutSumLocal    (discOutSumLocal ),
      .discOutSumNeighbour(discOutSumNeighbour),
      .sumPulse (sumPulse),
      .clk_read (clk_read ),
      .reset    (reset    ),
      .shutterA (shutter  ),
      .shutterB (shutter  ),
      .SerInA   (SerInA   ),
      .SerInB   (SerInB   ),
      .SerOutA  (SerOutA  ),
      .SerOutB  (SerOutB  ) 
   );
  
   reg     [3:0]  disOutNeighbour ;

   initial begin
      clk_read = 1'b0;
      forever begin
         #10 clk_read = ~ clk_read;
      end
   end

   initial begin
      shutter = 1'b0;
      SummingMode = 1'b0;
      discOutLocal = 1'b0;
      discOutSumLocal = 1'b0;
      ackFromNeighbour = 3'b000;
      discOutSumNeighbour = 3'b000;
      reset = 1'b1;
      discOutNeighbour = 4'b0000;
   end
endmodule 
