/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : pixelCell_inf.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Fri 09 Jul 2021 02:18:53 PM CST
 ************************************************************************/
 
interface pixelcell_inf(input bit clock, reset);
    // arbiter interface
    wire            discOutLocal  ;
    logic    [3:0]  discOutNear   ; 
    logic    [3:0]  ackToNear     ; 
    logic    [3:0]  ackFromNear   ; 

    // syncronization interface
    wire           discOutSumLocal;
    logic    [2:0]  discOutSumNear ; 

    // lsfr counter interface
    logic           SummingMode;
    logic           shutter;
    logic  [1:0]    SerIn ;
    logic  [1:0]    SerOut;

    modport dut (
        input  discOutNear, ackFromNear, discOutSumNear, SummingMode, shutter, SerIn, clock, reset,
        output discOutLocal, ackToNear, discOutSumLocal, SerOut
    );

    modport test (
        output  discOutNear, ackFromNear, discOutSumNear, SummingMode, shutter, SerIn,
        input   discOutLocal, ackToNear, discOutSumLocal, SerOut, clock, reset
    );
endinterface //pixelcell_inf