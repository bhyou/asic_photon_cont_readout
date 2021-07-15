/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : pixelArray.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Fri 09 Jul 2021 03:57:55 PM CST
 ************************************************************************/
`include "analog_env.sv"
`include "sensor_inf.sv"

module pixelArray;
    parameter Row = 3;
    parameter Col = 3;

    reg                 readClk ;
    reg                 reset   ;
    reg                 refClk  ;
    reg                 sumMode ;
    reg                 shutter ;
    reg  [Col-1:0]      serialIn [1:0];
    wire [Col-1:0]      serialOut[1:0];


    sensor_inf  sensorInf [Row*Col-1:0] (refClk);

    analog_environment #(Row, Col) analogEnv;

    dig_fe_array #(Row, Col) digitalFeArray(
        .readClk  (readClk),
        .reset    (reset  ),
        .sumMode  (sumMode),
        .shutter  (shutter),
        .SerInA   (serialIn[0] ),
        .SerInB   (serialIn[1] ),
        .SerOutA  (serialOut[0]),
        .SerOutB  (serialOut[1]),
        .sensorInf(sensorInf) 
    );

    initial begin
        readClk = 0;
        refClk  = 0;
        fork
            forever #10 readClk = ~readClk;
            forever #1 refClk = ~ refClk;
        join
    end

    initial begin
        reset   = 1'b1;
        sumMode = 1'b1;
        shutter = 1'b0;
        analogEnv = new(sensorInf);

        #10 ;
        reset   = 1'b0;
    end
endmodule

