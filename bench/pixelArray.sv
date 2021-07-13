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
    pixelcell_inf   pixCellInf [Row-1:0][Col-1:0];
    mailbox              mbx   [Row-1:0][Col-1:0];

    genvar x, y;
    generate
        for(int y=0; y < Row; y++) begin: YC
        for(int x=0; x < Col; x++) begin: XC
            if((x == Col-1) && (y == 0)) begin
            pixelcell cell_x_y(
                .CollectEnergyL  (energy[y][x]),
                .CollectEnergyS  ( 0.000 ),
                .CollectEnergyE  ( 0.000 ),
                .CollectEnergySE ( 0.000 ),
                .refclk          (refclk ),
                .pixCellInf      (pixelCellInf[y][x]) 
            );
            end
            else if((x != Col-1) && (y == 0)) begin
            pixelcell cell_x_y(
                .CollectEnergyL  (energy[y][x]),
                .CollectEnergyS  ( 0.000      ),
                .CollectEnergyE  (energy[y][x+1]),
                .CollectEnergySE ( 0.0000     ),
                .refclk          (refclk         ),
                .pixCellInf      (pixelCellInf[y][x]) 
            );
            end
            else if((x == Col-1) && (y != 0)) begin
            pixelcell cell_x_y(
                .CollectEnergyL  (energy[y][x]),
                .CollectEnergyS  (energy[y-1][x]),
                .CollectEnergyE  ( 0.0000 ),
                .CollectEnergySE ( 0.0000 ),
                .refclk          (refclk  ),
                .pixCellInf      (pixelCellInf[y][x]) 
            );
            end
            else begin
            pixelcell cell_x_yi #(.CoorX(25*x), .CoorY(25*y)) (
                .CollectEnergyL  (energy[y][x]    ),
                .CollectEnergyS  (energy[y-1][x]  ),
                .CollectEnergyE  (energy[y][x+1]  ),
                .CollectEnergySE (energy[y-1][x+1]),
                .refclk          (refclk          ),
                .pixCellInf      (pixelCellInf[y][x]) 
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
                    serialOutput[x] = pixelCellInf[y][x].serOut;
                else if(y==Row-1) 
                    pixelCellInf[y][x].SerIn = serialInput[x];
                else 
                    pixelCellInf[y][x].SerIn = pixelCellInf[y+1][x].SerOut;

                pixelCellInf[y][x].SummingMode = summingMode;
                pixelCellInf[y][x].shutter = outShutter;
            end 
        end
    endgenerate

    //  connect local discriminator  output to arbiter
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                //  get the local discriminator output from southern pixel
                if(y==0)  
                    assign pixelCellInf[y][x].discOutNear[0] = 1'b0; 
                else  
                    assign pixelCellInf[y][x].discOutNear[0] = pixelCellInf[y-1][x].discOutLocal; 
                // get the local discriminator output from southeastern pixel
                if(y==0 || x==Col-1) 
                    assign pixelCellInf[y][x].discOutNear[1] = 1'b0;
                else  
                    assign pixelCellInf[y][x].discOutNear[1] = pixelCellInf[y-1][x+1].discOutLocal;
                // get the local discriminator output from eastern pixel
                if(x==Col-1)  
                    assign pixelCellInf[y][x].discOutNear[2] = 1'b0;
                else          
                    assign pixelCellInf[y][x].discOutNear[2] = pixelCellInf[y][x+1].discOutLocal;
                // get the local discriminator output from northeastern pixel
                if(y==Row-1 || x==Col-1) 
                    assign pixelCellInf[y][x].discOutNear[3] = 1'b0;
                else
                    assign pixelCellInf[y][x].discOutNear[3] = pixelCellInf[y+1][x+1].discOutLocal;
            end
        end
    endgenerate

    // acknowledge from neighours pixel, such as north,  north-west, west, and south-west
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                // acknowledge from northern neighbor pixel
                if(y==Row-1)  
                    assign pixelCellInf[y][x].ackFromNear[0] = 1'b0;
                else 
                    assign pixelCellInf[y][x].ackFromNear[0] = pixelCellInf[y+1][x].ackToNear[0];
                // acknowledge from northwestern neighbor pixel
                if(y==Row-1 || x==0)
                    assign pixelCellInf[y][x].ackFromNear[1] = 1'b0;
                else 
                    assign pixelCellInf[y][x].ackFromNear[1] = pixelCellInf[y+1][x-1].ackToNear[1];
                // acknowledge from western neighbor pixel
                if(x==0)  
                    assign pixelCellInf[y][x].ackFromNear[2] = 1'b0;
                else 
                    assign pixelCellInf[y][x].ackFromNear[2] = pixelCellInf[y][x-1].ackToNear[2];
                // acknowledge from southwest neighbor pixel
                if(y==0 || x==0)  
                    assign pixelCellInf[y][x].ackFromNear[3] = 1'b0;
                else 
                    assign pixelCellInf[y][x].ackFromNear[3] = pixelCellInf[y-1][x-1].ackToNear[3];
            end
        end
    endgenerate
    
    // synchronization logic connect
    generate
        for(y=0; y < Row; y++) begin
            for(x=0; x < Col; x++) begin
                // get the summing discriminator output from northern pixel
                if(x==0)  
                    assign pixelCellInf[y][x].disOutSumNear[2] = 1'b0; 
                else  
                    assign pixelCellInf[y][x].disOutSumNear[2] = pixelCellInf[y][x-1].discOutSumLocal;   
                // get the summing discriminator output from northwestern pixel
                if(x==0 || y==Row-1)  
                    assign pixelCellInf[y][x].disOutSumNear[1] = 1'b0; 
                else  
                    assign pixelCellInf[y][x].disOutSumNear[1] = pixelCellInf[y+1][x-1].discOutSumLocal; 
                // get the local discriminator output from western pixel
                if(y==Row-1)  
                    assign pixelCellInf[y][x].disOutSumNear[0] = 1'b0; 
                else 
                    assign pixelCellInf[y][x].disOutSumNear[0] = pixelCellInf[y+1][x].discOutSumLocal;   
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

