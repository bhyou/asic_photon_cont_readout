/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../bench/pixelCell.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 07 Jul 2021 05:07:01 PM CST
 ************************************************************************/
 
module pixelCell(
    output real          collectEnergyL,
    input  real          collectEnergyS,
    input  real          collectEnergyE,
    input  real          collectEnergySE,
    output logic         discOutLocal  ,

    input  wire          SummingMode   ,
    input  wire   [3:0]  discOutNear   ,
    output wire   [3:0]  ackToNear     ,

    input  wire   [3:0]  ackFromNear   ,
//    output wire          hitPulse    ,

    input  wire   [2:0]  discOutSumNear,
//    output wire          sumPulse    ,

    input  wire          clk_read ,
    input  wire          reset    ,
    input  wire          shutter  ,
    input  wire          SerInA   ,
    input  wire          SerInB   ,
    output wire          SerOutA  ,
    output wire          SerOutB 
);

    parameter CoorX = 25;
    parameter CoorY = 25;

    mailbox              receivePhotons;
    sensor               sernsor;

    initial begin
        photon      photon;
        sensor = new(CoorY,CoorY,receivePhotons);
        forever begin
            receivePhotons.get(photon);
            sensor.convert_energy_to_voltage(collectEnergyL);
        end
    end
    

    digit_front_end u_digFrontEnd(
        .SummingMode         (SummingMode    ),
        .discOutNeighbour    (discOutNear    ),
        .ackToNeighbour      (ackToNear      ),
        .discOutLocal        (discOutLocal   ),
        .ackFromNeighbour    (ackFromNear    ),
        .hitPulse            (               ),
        .discOutSumLocal     (discOutSumLocal),
        .discOutSumNeighbour (discOutSumNear ),
        .sumPulse            (               ),
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