/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../bench/pixelCell.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 07 Jul 2021 05:07:01 PM CST
 ************************************************************************/
`include "analog_front_end.sv"

module pixelcell(
    output real          collectEnergyL,
    input  real          collectEnergyS,
    input  real          collectEnergyE,
    input  real          collectEnergySE,
    input  wire          refclk        ,
    pixelcell_inf.dut    pixCellInf    
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

    assign pixCellInf.discOutLocal    = sensorInf.discOutLocal;
    assign pixCellInf.discOutSumLocal = sensorInf.discOutSum;     

    digit_front_end u_digFrontEnd(
        .SummingMode         (pixCellInf.SummingMode    ),
        .discOutNeighbour    (pixCellInf.discOutNear    ),
        .ackToNeighbour      (pixCellInf.ackToNear      ),
        .discOutLocal        (pixCellInf.discOutLocal   ),
        .ackFromNeighbour    (pixCellInf.ackFromNear    ),
        .discOutSumLocal     (pixCellInf.discOutSumLocal),
        .discOutSumNeighbour (pixCellInf.discOutSumNear ),
        .clk_read            (pixCellInf.clock    ),
        .reset               (pixCellInf.reset    ),
        .shutterA            (pixCellInf.shutter  ),
        .shutterB            (pixCellInf.shutter  ),
        .SerInA              (pixCellInf.SerIn[0] ),
        .SerInB              (pixCellInf.SerIn[1] ),
        .SerOutA             (pixCellInf.SerOut[0]),
        .SerOutB             (pixCellInf.SerOut[1]) 
    );
endmodule

`ifdef testingPixelCells
`include "generator.sv"
`include "pixelCell_inf.sv"
module  pixelCell_tb ;
   
    real            energyS;
    real            energyE;
    real            energySE;
    real            energyL;

    reg             refclk;
    reg             clock;
    reg             reset;

    generator       Gen;
    mailbox         mbx;

    pixelcell_inf    pixelCellInf(clock, reset); 

    pixelcell  u_cell0(
        .collectEnergyL  (energyL ),
        .collectEnergyS  (energyS ),
        .collectEnergyE  (energyE ),
        .collectEnergySE (energySE),
        .refclk          (refclk         ),
        .pixCellInf      (pixelCellInf   ) 
    );
    
    initial begin
        mbx = new();
        Gen = new(mbx);     
        Gen.hitsNumber = 1;   
        Gen.genData();
        u_cell0.mbx = mbx;
    end

    initial begin
        refclk = 0;
        forever begin
            #1 refclk = ~refclk;
        end
    end

    initial begin
        clock = 0;
        forever begin
            #10 clock = ~ clock;
        end
    end

    initial begin
        reset = 1'b1;
        #35;
        reset = 1'b0;
    end

    initial begin
        energyS  = 20;
        energyE  = 20;
        energySE = 20;
        pixelCellInf.discOutNear = '0;
        pixelCellInf.ackFromNear = '0;
        pixelCellInf.discOutSumNear = '0;
        pixelCellInf.SummingMode = '1;
        pixelCellInf.shutter = '0;
        pixelCellInf.SerIn   = '0;
        #300000;
        $stop();
    end
endmodule

`endif 