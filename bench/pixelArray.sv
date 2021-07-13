/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : pixelArray.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Fri 09 Jul 2021 03:57:55 PM CST
 ************************************************************************/
`include "pixelCell.sv" 
`include "generator.sv"
`include "pixelCell_inf.sv"

module pixelArray;
    parameter Row = 2;
    parameter Col = 2;

    reg                 simmingMode  ;
    reg                 outShutter   ;
    reg  [Col-1:0]      serialInput  ;
    wire [Col-1:0]      serialOutput ;

    real                energy [Row-1:0][Col-1:0];
    pixelcell_inf       pixInf [Row*Col-1:0];
    mailbox              mbx   [Row*Col-1:0];

    genvar x, y;
    generate
        for(int y=0; y < Row; y++) begin: YC   // coordinate of y
        for(int x=0; x < Col; x++) begin: XC   // coordinate of x
            if((x == Col-1) && (y == 0)) begin
            pixelcell cell_x_y(
                .CollectEnergyL  (energy[y][x]),
                .CollectEnergyS  ( 0.000 ),
                .CollectEnergyE  ( 0.000 ),
                .CollectEnergySE ( 0.000 ),
                .refclk          (refclk ),
                .pixInf          (pixInf[y*Col+x]) 
            );
            end
            else if((x != Col-1) && (y == 0)) begin
            pixelcell cell_x_y(
                .CollectEnergyL  (energy[y][x]),
                .CollectEnergyS  ( 0.000      ),
                .CollectEnergyE  (energy[y][x+1]),
                .CollectEnergySE ( 0.0000     ),
                .refclk          (refclk         ),
                .pixInf          (pixInf[y*Col+x]) 
            );
            end
            else if((x == Col-1) && (y != 0)) begin
            pixelcell cell_x_y(
                .CollectEnergyL  (energy[y][x]),
                .CollectEnergyS  (energy[y-1][x]),
                .CollectEnergyE  ( 0.0000 ),
                .CollectEnergySE ( 0.0000 ),
                .refclk          (refclk  ),
                .pixInf          (pixInf[y*Col+x]) 
            );
            end
            else begin
            pixelcell cell_x_yi #(.CoorX(25*x), .CoorY(25*y)) (
                .CollectEnergyL  (energy[y][x]    ),
                .CollectEnergyS  (energy[y-1][x]  ),
                .CollectEnergyE  (energy[y][x+1]  ),
                .CollectEnergySE (energy[y-1][x+1]),
                .refclk          (refclk          ),
                .pixInf          (pixInf[y*Col+x]) 
            );
            end
        end
        end
    endgenerate

    // lsfr readout connect  
    generate
        for(x=0; x < Col; y++) begin
            for(y=0; y <Row; y++) begin 
                if(y==0) 
                    serialOutput[x] = pixInf[y*Col+x].serOut;
                else if(y==Row-1) 
                    pixInf[y*Col+x].SerIn = serialInput[x];
                else 
                    pixInf[y*Col+x].SerIn = pixInf[(y+1)*Col+x].SerOut;

                pixInf[y*Col+x].SummingMode = summingMode;
                pixInf[y*Col+x].shutter = outShutter;
            end 
        end
    endgenerate

    //  connect local discriminator  output to arbiter
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                //  get the local discriminator output from southern pixel
                if(y==0)  
                    assign pixInf[y*Col+x].discOutNear[0] = 1'b0; 
                else  
                    assign pixInf[y*Col+x].discOutNear[0] = pixInf[(y-1)*Col+x].discOutLocal; 
                // get the local discriminator output from southeastern pixel
                if(y==0 || x==Col-1) 
                    assign pixInf[y*Col+x].discOutNear[1] = 1'b0;
                else  
                    assign pixInf[y*Col+x].discOutNear[1] = pixInf[(y-1)*Col+x+1].discOutLocal;
                // get the local discriminator output from eastern pixel
                if(x==Col-1)  
                    assign pixInf[y*Col+x].discOutNear[2] = 1'b0;
                else          
                    assign pixInf[y*Col+x].discOutNear[2] = pixInf[y*Col+x+1].discOutLocal;
                // get the local discriminator output from northeastern pixel
                if(y==Row-1 || x==Col-1) 
                    assign pixInf[y*Col+x].discOutNear[3] = 1'b0;
                else
                    assign pixInf[y*Col+x].discOutNear[3] = pixInf[(y+1)*Col+x+1].discOutLocal;
            end
        end
    endgenerate

    // acknowledge from neighours pixel, such as north,  north-west, west, and south-west
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                // acknowledge from northern neighbor pixel
                if(y==Row-1)  
                    assign pixInf[y*Col+x].ackFromNear[0] = 1'b0;
                else 
                    assign pixInf[y*Col+x].ackFromNear[0] = pixInf[(y+1)*Col+x].ackToNear[0];
                // acknowledge from northwestern neighbor pixel
                if(y==Row-1 || x==0)
                    assign pixInf[y*Col+x].ackFromNear[1] = 1'b0;
                else 
                    assign pixInf[y*Col+x].ackFromNear[1] = pixInf[(y+1)*Col+x-1].ackToNear[1];
                // acknowledge from western neighbor pixel
                if(x==0)  
                    assign pixInf[y*Col+x].ackFromNear[2] = 1'b0;
                else 
                    assign pixInf[y*Col+x].ackFromNear[2] = pixInf[y*Col+x-1].ackToNear[2];
                // acknowledge from southwest neighbor pixel
                if(y==0 || x==0)  
                    assign pixInf[y*Col+x].ackFromNear[3] = 1'b0;
                else 
                    assign pixInf[y*Col+x].ackFromNear[3] = pixInf[(y-1)*Col+x-1].ackToNear[3];
            end
        end
    endgenerate
    
    // synchronization logic connect
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                // get the summing discriminator output from northern pixel
                if(x==0)  
                    assign pixInf[y*Col+x].disOutSumNear[2] = 1'b0; 
                else  
                    assign pixInf[y*Col+x].disOutSumNear[2] = pixInf[y*Col+x-1].discOutSumLocal;   
                // get the summing discriminator output from northwestern pixel
                if(x==0 || y==Row-1)  
                    assign pixInf[y*Col+x].disOutSumNear[1] = 1'b0; 
                else  
                    assign pixInf[y*Col+x].disOutSumNear[1] = pixInf[(y+1)*Col+x-1].discOutSumLocal; 
                // get the local discriminator output from western pixel
                if(y==Row-1)  
                    assign pixInf[y*Col+x].disOutSumNear[0] = 1'b0; 
                else 
                    assign pixInf[y*Col+x].disOutSumNear[0] = pixInf[(y+1)*Col+x].discOutSumLocal;   
            end
        end
    endgenerate

    initial begin
        for (int y=0; y < Row; y++) begin
            for (int x=0; x < Col; x++) begin
      //          YC[y]XC[x].mbx = mbx[y][x]; 
            end
        end
    end

    initial begin
        summingMode = 1'b0;
        outShutter  = 1'b0;
        serialInput = 2'h0;
    end
endmodule

