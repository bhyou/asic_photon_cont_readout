/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : discriminator.svh
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
`include "defines.sv"
interface sensor_inf ( input bit clock);
    logic discOutLocal;
    logic discOutSum;
endinterface //sensor_inf

class discriminator;

    virtual sensor_inf sensorInf;

    function new(virtual sensor_inf sensorInf);
        this.sensorInf = sensorInf;
    endfunction //new()

    task automatic local_compare(real localVoltage);
        $display("@%0t the local voltage : %0d",$time, localVoltage);
        if(localVoltage > `LocalThreshold) begin
            sensorInf.discOutLocal = 1'b0;
            repeat(50-localVoltage/2) 
            @(sensorInf.clock);

            sensorInf.discOutLocal = 1'b1;
            repeat(localVoltage) 
            @(sensorInf.clock);

            sensorInf.discOutLocal = 1'b0;
            repeat(50-localVoltage/2) 
            @(sensorInf.clock);
        end
        else
            sensorInf.discOutLocal = 1'b0;
    endtask // local_compare

    task automatic summing_compare(real voltageL, voltageS, voltageE, voltageSE);
        real summingVoltage = voltageL + voltageS + voltageSE + voltageE;
        $display("@%0t the summing voltage : %0d",$time, summingVoltage);
        if(summingVoltage > `SummingThreshold) begin
            sensorInf.discOutSum = 1'b0;
            repeat(50-summingVoltage/2) 
            @(sensorInf.clock);

            sensorInf.discOutSum = 1'b1;
            repeat(summingVoltage) 
            @(sensorInf.clock);

            sensorInf.discOutSum = 1'b0;
            repeat(50-summingVoltage/2) 
            @(sensorInf.clock);
        end
        else
            sensorInf.discOutSum = 1'b0;
    endtask // summing_compare

    // how to transfer output to inerface ?
/*
    task generate_pulse(output logic voltage, real collectEnergy, int range);
        voltage = 1'b0;
        #(range/2-collectEnergy/2);
        voltage = 1'b1;
        #(collectEnergy);
        voltage = 1'b0;
        #(range/2-collectEnergy/2);
    endtask
*/

endclass //discriminator

`ifdef testingDiscriminator
module test;
    reg    clock;
    wire   discOutLocal;
    wire   discOutSum;

    discriminator disc;    
    sensor_inf sensorInf (clock);

    assign discOutSum   = sensorInf.discOutSum;
    assign discOutLocal = sensorInf.discOutLocal;


    initial begin
        clock = 1'b0;
        forever begin
            #1 clock = ~clock;
        end
    end

    initial begin
        disc = new(sensorInf);
        disc.local_compare(30);
        disc.summing_compare(20,10,30,40); 
    end
endmodule
`endif