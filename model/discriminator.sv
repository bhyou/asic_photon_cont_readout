/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : discriminator.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 07 Jul 2021 05:29:44 PM CST
 ************************************************************************/

// ----------------------------------------------------------------
//  a over-threshold comparator is descripted in the comparator class.
//
// function:
//   as common comparator, this over-threshold comparator will generate a pulse
//   based on the collected energy or charge.
// ----------------------------------------------------------------
module discrinator(
    input  real    collectEnergyL,
    input  real    collectEnergyS,
    input  real    collectEnergySE,
    input  real    collectEnergyE,
    output logic   discOutLocal ,
    output logic   discOutSum
);
    real summingEnergy;

    initial begin
        forever begin
            if(collectEnergyL > `LocalThreshold)
                generate_pulse(collectEnergyL, discOutLocal);
            else 
                discOutLocal = 1'b0;
        end
    end

    initial begin
        forever begin 
            summingEnergy = collectEnergyS + collectEnergySE + 
                            collectEnergyE + collectEnergyL;
            if(summingEnergy > `SummingThreshold)
                generate_pulse(summingEnergy, discOutSum);
            else
                discOutSum = 1'b0;
        end
    end

    task generate_pulse(real collectEnergy, ref discOut);
        discOut = 1'b0;
        #(50-collectEnergy/2);
        discOut = 1'b1;
        #(collectEnergy);
        discOut = 1'b0;
        #(50-collectEnergy/2);
    endtask

endmodule