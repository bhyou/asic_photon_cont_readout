/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../bench/dig_fe_array.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 14 Jul 2021 10:19:24 PM CST
 ************************************************************************/
 
module dig_fe_array #(
    parameter Row = 2, 
    parameter Col = 2) (
    input  wire           readClk,
    input  wire           reset  ,
    input  wire           sumMode,
    input  wire           shutter,
    input  wire [Col-1:0] SerInA,
    input  wire [Col-1:0] SerInB,
    input  wire [Col-1:0] SerOutA,
    input  wire [Col-1:0] SerOutB,
    // discriminator out
    sensor_inf  sensorInf [Row*Col-1:0]
);

    wire [3:0] [Col-1:0]  discOutNear [Row-1:0];
    wire [3:0] [Col-1:0]  ackToNear   [Row-1:0];
    wire       [Col-1:0]  discOutSelf [Row-1:0];
    wire [3:0] [Col-1:0]  ackFromNear [Row-1:0];
    wire       [Col-1:0]  discOutSum  [Row-1:0];
    wire [2:0] [Col-1:0]  discSumMear [Row-1:0];

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
                   .discOutSumNeighbour (discSumMear[y][x]),

                   .clk_read       (readClk ),
                    .SummingMode   (sumMode ),
                   .reset          (reset   ),
                   .shutterA       (shutter ),
                   .shutterB       (shutter ),
                   .SerInA         (serialInA[y]][x] ),
                   .SerInB         (serialInB[y]][x] ),
                   .SerOutA        (serialOutA[y][x] ),
                   .SerOutB        (serialOutB[y][x] )
                );
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
                    assign ackFromNear[y][x][0] = 1'b0;
                else 
                    assign ackFromNear[y][x][0] = ackToNear[y+1][x][0];

                // acknowledge from northwestern neighbor pixel
                if(y==Row-1 || x==0)
                    assign ackFromNear[y][x][1] = 1'b0;
                else 
                    assign ackFromNear[y][x][1] = ackToNear[y+1][x-1][1];

                // acknowledge from western neighbor pixel
                if(x==0)  
                    assign ackFromNear[y][x][2] = 1'b0;
                else 
                    assign ackFromNear[y][x][2] = ackToNear[y][x-1][2];

                // acknowledge from southwest neighbor pixel
                if(y==0 || x==0)  
                    assign ackFromNear[y][x][3] = 1'b0;
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
                if(x==0)  
                    assign discSumNear[y][x][2] = 1'b0; 
                else  
                    assign discSumNear[y][x][2] = discOutSum[y+1][x];

                // get the summing discriminator output from northwestern pixel
                if(x==0 || y==Row-1)  
                    assign discSumNear[y][x][1] = 1'b0; 
                else  
                    assign discSumNear[y][x][1] = discOutSum[y+1][x-1]; 

                // get the local discriminator output from western pixel
                if(y==Row-1)  
                    assign discSumNear[y][x][0] = 1'b0; 
                else 
                    assign discSumNear[y][x][0] = discOutSum[y][x-1]; 
            end
        end
    endgenerate
endmodule