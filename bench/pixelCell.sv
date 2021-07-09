/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../bench/pixelCell.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 07 Jul 2021 05:07:01 PM CST
 ************************************************************************/
`include "analog_front_end.sv"

module pixelCell(
    output real          collectEnergyL,
    input  real          collectEnergyS,
    input  real          collectEnergyE,
    input  real          collectEnergySE,
    output wire          discOutLocal  ,

    input  wire          SummingMode   ,
    input  wire   [3:0]  discOutNear   ,
    output wire   [3:0]  ackToNear     ,
    input  wire   [3:0]  ackFromNear   ,

    output wire          discOutSumLocal,
    input  wire   [2:0]  discOutSumNear,
    input  wire          refclk  ,
    input  wire          clk_read ,
    input  wire          reset    ,
    input  wire          shutter  ,
    input  wire          SerInA   ,
    input  wire          SerInB   ,
    output wire          SerOutA  ,
    output wire          SerOutB  ,
);
    parameter CoorX = 25;
    parameter CoorY = 25;
    sensor_inf sensorInf (refclk);
    mailbox              mbx;
    analog_front_end     aFE;

    initial begin
        photon      photon;
        aFE = new(CoorX,CoorY,mbx,sensorInf);

        forever begin
            aFE.hit_reaction(collectEnergyS,collectEnergyE,collectEnergySE,collectEnergyL);
        end
    end

    assign discOutLocal    = sensorInf.discOutLocal;
    assign discOutSumLocal = sensorInf. discOutSumLocal;     

    digit_front_end u_digFrontEnd(
        .SummingMode         (SummingMode    ),
        .discOutNeighbour    (discOutNear    ),
        .ackToNeighbour      (ackToNear      ),
        .discOutLocal        (discOutLocal   ),
        .ackFromNeighbour    (ackFromNear    ),
        .discOutSumLocal     (discOutSumLocal),
        .discOutSumNeighbour (discOutSumNear ),
        .clk_read            (clk_read       ),
        .reset               (reset          ),
        .shutterA            (shutter        ),
        .shutterB            (shutter        ),
        .SerInA              (SerInA         ),
        .SerInB              (SerInB         ),
        .SerOutA             (SerOutA        ),
        .SerOutB             (SerOutB        ) 
    );

endmodule
