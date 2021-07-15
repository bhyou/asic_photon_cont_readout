/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../bench/dig_fe_array.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 14 Jul 2021 10:19:24 PM CST
 ************************************************************************/
`include "defines.sv"
`include "sensor_inf.sv"
module dig_fe_array #(
    parameter Row = 2, 
    parameter Col = 2) (
    input  wire           readClk,
    input  wire           reset  ,
    input  wire           sumMode,
    input  wire           shutter,
    input  wire [Col-1:0] SerInA,
    input  wire [Col-1:0] SerInB,
    output wire [Col-1:0] SerOutA,
    output wire [Col-1:0] SerOutB,
    // discriminator out
    sensor_inf  sensorInf [Row*Col-1:0]
);

    wire [3:0]   discOutNear [Row-1:0][Col-1:0];
    wire [3:0]   ackToNear   [Row-1:0][Col-1:0];
    wire         discOutSelf [Row-1:0][Col-1:0];
    wire [3:0]   ackFromNear [Row-1:0][Col-1:0];
    wire         discOutSum  [Row-1:0][Col-1:0];
    wire [2:0]   discSumNear [Row-1:0][Col-1:0];

    wire [Col-1:0]  serialInA   [Row-1:0];
    wire [Col-1:0]  serialInB   [Row-1:0];
    wire [Col-1:0]  serialOutA  [Row-1:0];
    wire [Col-1:0]  serialOutB  [Row-1:0];

    genvar x, y;
    generate
        for (y = 0; y < Row; y++) begin: YC
            for (x =0; x < Col; x++) begin: XC
                digit_front_end u_digFrontEnd(
                   .discOutNeighbour    (discOutNear[y][x]),
                   .ackToNeighbour      (ackToNear[y][x]  ),
                   .discOutLocal        (discOutSelf[y][x]),
                   .ackFromNeighbour    (ackFromNear[y][x]),
                   .discOutSumLocal     (discOutSum[y][x] ),
                   .discOutSumNeighbour (discSumNear[y][x]),

                   .clk_read       (readClk ),
                    .SummingMode   (sumMode ),
                   .reset          (reset   ),
                   .shutterA       (shutter ),
                   .shutterB       (shutter ),
                   .SerInA         (serialInA[y][x] ),
                   .SerInB         (serialInB[y][x] ),
                   .SerOutA        (serialOutA[y][x] ),
                   .SerOutB        (serialOutB[y][x] )
                );

                assign discOutSelf[y][x] = sensorInf[y*Col+x].discOutLocal;
                assign discOutSum[y][x]  = sensorInf[y*Col+x].discOutSum;
            end
        end
    endgenerate

    // serial readout connection
    generate
        for(y = 0; y < Row; y++) begin
            if(y==Row-1) begin
                assign serialInA[Row-1] = SerInA;
                assign serialInB[Row-1] = SerInB;
            end
            else begin
                assign serialInA[y] = serialOutA[y+1];
                assign serialInB[y] = serialOutB[y+1];
            end
        end
    endgenerate
    assign SerOutA = serialOutA[0];
    assign SerOutB = serialOutB[0];

    // discriminator output connection
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                //  get the local discriminator output from southern pixel
                if(y==0)  
                    assign discOutNear[y][x][0] = 1'b0; 
                else  
                    assign discOutNear[y][x][0] = discOutSelf[y-1][x]; 

                // get the local discriminator output from southeastern pixel
                if(y==0 || x==Col-1) 
                    assign discOutNear[y][x][1] = 1'b0;
                else  
                    assign discOutNear[y][x][1] = discOutSelf[y-1][x+1];

                // get the local discriminator output from eastern pixel
                if(x==Col-1)  
                    assign discOutNear[y][x][2] = 1'b0;
                else          
                    assign discOutNear[y][x][2] = discOutSelf[y][x+1];

                // get the local discriminator output from northeastern pixel
                if(y==Row-1 || x==Col-1) 
                    assign discOutNear[y][x][3] = 1'b0;
                else
                    assign discOutNear[y][x][3] = discOutSelf[y+1][x+1];
            end
        end
    endgenerate

    // acknowledge from neighours pixel, such as north,  north-west, west, and south-west
    generate
        for(y=0; y < Row; y++) begin 
            for(x=0; x < Col; x++) begin
                // acknowledge from northern neighbor pixel
                if(y==Row-1)  
                    assign ackFromNear[y][x][0] = 1'b1;
                else 
                    assign ackFromNear[y][x][0] = ackToNear[y+1][x][0];

                // acknowledge from northwestern neighbor pixel
                if(y==Row-1 || x==0)
                    assign ackFromNear[y][x][1] = 1'b1;
                else 
                    assign ackFromNear[y][x][1] = ackToNear[y+1][x-1][1];

                // acknowledge from western neighbor pixel
                if(x==0)  
                    assign ackFromNear[y][x][2] = 1'b1;
                else 
                    assign ackFromNear[y][x][2] = ackToNear[y][x-1][2];

                // acknowledge from southwest neighbor pixel
                if(y==0 || x==0)  
                    assign ackFromNear[y][x][3] = 1'b1;
                else 
                    assign ackFromNear[y][x][3] = ackToNear[y-1][x-1][3];
            end
        end
    endgenerate

    // synchronization logic connect
    generate
        for(y=0; y < Row; y++) begin: syncLinkY
            for(x=0; x < Col; x++) begin: syncLinkX
                // get the summing discriminator output from northern pixel
                if(y==Row-1)  
                    assign discSumNear[y][x][0] = 1'b0; 
                else  
                    assign discSumNear[y][x][0] = discOutSum[y+1][x];

                // get the summing discriminator output from northwestern pixel
                if(x==0 || y==Row-1)  
                    assign discSumNear[y][x][1] = 1'b0; 
                else  
                    assign discSumNear[y][x][1] = discOutSum[y+1][x-1]; 

                // get the summing discriminator output from western pixel
                if(x==0)  
                    assign discSumNear[y][x][2] = 1'b0; 
                else 
                    assign discSumNear[y][x][2] = discOutSum[y][x-1]; 
            end
        end
    endgenerate
endmodule


`ifdef verifyDigFrontEndArray
module digitFrontEnd_tb;
    parameter Row = 2;
    parameter Col = 2;

    reg            readClk;
    reg            reset  ;
    reg            sumMode;
    reg            shutter;
    reg  [Col-1:0] SerInA ;
    reg  [Col-1:0] SerInB ;
    wire [Col-1:0] SerOutA;
    wire [Col-1:0] SerOutB;

    reg            clock;
    sensor_inf  sensorInf [Row*Col-1:0](clock);

    dig_fe_array #(2,2) u_digArray(
        .readClk  (readClk  ),
        .reset    (reset    ),
        .sumMode  (sumMode  ),
        .shutter  (shutter  ),
        .SerInA   (SerInA   ),
        .SerInB   (SerInB   ),
        .SerOutA  (SerOutA  ),
        .SerOutB  (SerOutB  ),
        .sensorInf(sensorInf) 
    );

    initial begin
        readClk = 1'b0;
        forever begin
            #20  readClk = ~readClk;
        end
    end

    initial begin
        clock = 0;
        forever begin
            #1 clock = ~clock;
        end
    end

    initial begin
        reset   = 1'b1;
        sumMode = 1'b1;
        shutter = 1'b0;
        SerInA  = '0;
        SerInB  = '0;

        #10 ;
        reset = 1'b0;
    end

    initial begin
        for(int item =0 ; item < Row*Col; item++) begin
            set_local_discriminate(item,1'b0) ;
            set_summing_discriminate(item,1'b0);
        end

        fork
            sensorInf[0].local_discriminate(4);
            sensorInf[0].summing_discriminate(12);

            sensorInf[1].local_discriminate(8);
            sensorInf[1].summing_discriminate(8);

            sensorInf[2].local_discriminate(12);
            sensorInf[2].summing_discriminate(40);

            sensorInf[3].local_discriminate(16);
            sensorInf[3].summing_discriminate(24);
        join
        #200;
    end

    task set_local_discriminate(int index,bit bitVal);
        case(index)
            0: sensorInf[0].discOutLocal = bitVal;
            1: sensorInf[1].discOutLocal = bitVal;
            2: sensorInf[2].discOutLocal = bitVal;
            3: sensorInf[3].discOutLocal = bitVal;
        endcase
    endtask

    task set_summing_discriminate(int index, bit bitVal);
        case(index)
            0: sensorInf[0].discOutSum = bitVal;
            1: sensorInf[1].discOutSum = bitVal;
            2: sensorInf[2].discOutSum = bitVal;
            3: sensorInf[3].discOutSum = bitVal;
        endcase
    endtask
endmodule

`endif