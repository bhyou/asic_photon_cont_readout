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

    reg                 summingMode  ;
    reg                 outShutter   ;
    reg  [Col-1:0]      serialInput  ;
    wire [Col-1:0]      serialOutput ;

    reg                 clk, rst;
    reg                 refclk;

    real                energy [Row-1:0][Col-1:0];
    pixelcell_inf       pixInf [Row*Col-1:0] (.clock(clk), .reset(rst));
    mailbox             mbx   [Row*Col-1:0];

    genvar x, y;
    generate
        for(y=0; y < Row; y++) begin: YC   // coordinate of y
        for(x=0; x < Col; x++) begin: XC   // coordinate of x
            if((x == Col-1) && (y == 0)) begin
            pixelcell #(.CoorX(25*x), .CoorY(25*y)) cell_x_y(
                .collectEnergyL  (energy[y][x]),
                .collectEnergyS  ( 0.000 ),
                .collectEnergyE  ( 0.000 ),
                .collectEnergySE ( 0.000 ),
                .refclk          (refclk ),
                .pixCellInf      (pixInf[y*Col+x]) 
            );
            end
            else if((x != Col-1) && (y == 0)) begin
            pixelcell #(.CoorX(25*x), .CoorY(25*y)) cell_x_y(
                .collectEnergyL  (energy[y][x]),
                .collectEnergyS  ( 0.000      ),
                .collectEnergyE  (energy[y][x+1]),
                .collectEnergySE ( 0.0000     ),
                .refclk          (refclk         ),
                .pixCellInf      (pixInf[y*Col+x]) 
            );
            end
            else if((x == Col-1) && (y != 0)) begin
            pixelcell #(.CoorX(25*x), .CoorY(25*y)) cell_x_y(
                .collectEnergyL  (energy[y][x]),
                .collectEnergyS  (energy[y-1][x]),
                .collectEnergyE  ( 0.0000 ),
                .collectEnergySE ( 0.0000 ),
                .refclk          (refclk  ),
                .pixCellInf      (pixInf[y*Col+x]) 
            );
            end
            else begin
            pixelcell #(.CoorX(25*x), .CoorY(25*y)) cell_x_y (
                .collectEnergyL  (energy[y][x]    ),
                .collectEnergyS  (energy[y-1][x]  ),
                .collectEnergyE  (energy[y][x+1]  ),
                .collectEnergySE (energy[y-1][x+1]),
                .refclk          (refclk          ),
                .pixCellInf      (pixInf[y*Col+x]) 
            );
            end
        end
        end
    endgenerate

    // lsfr readout connect  
    generate
        for(x=0; x < Col; x++) begin: lsfrX
            for(y=0; y <Row; y++) begin : lsfrY
                if(y==0) 
                    assign serialOutput[x] = pixInf[y*Col+x].SerOut;
                else if(y==Row-1) 
                    assign pixInf[y*Col+x].SerIn = serialInput[x];
                else 
                    assign pixInf[y*Col+x].SerIn = pixInf[(y+1)*Col+x].SerOut;

                assign pixInf[y*Col+x].SummingMode = summingMode;
                assign pixInf[y*Col+x].shutter = outShutter;
            end 
        end
    endgenerate

    //  connect local discriminator  output to arbiter
    generate
        for(y=0; y < Row; y++) begin: arbiterLinkX
            for(x=0; x < Col; x++) begin: arbiterLinkY
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
        for(y=0; y < Row; y++) begin: ackLinkY
            for(x=0; x < Col; x++) begin: akLinkYX
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
        for(y=0; y < Row; y++) begin: syncLinkY
            for(x=0; x < Col; x++) begin: syncLinkX
                // get the summing discriminator output from northern pixel
                if(x==0)  
                    assign pixInf[y*Col+x].discOutSumNear[2] = 1'b0; 
                else  
                    assign pixInf[y*Col+x].discOutSumNear[2] = pixInf[y*Col+x-1].discOutSumLocal;   
                // get the summing discriminator output from northwestern pixel
                if(x==0 || y==Row-1)  
                    assign pixInf[y*Col+x].discOutSumNear[1] = 1'b0; 
                else  
                    assign pixInf[y*Col+x].discOutSumNear[1] = pixInf[(y+1)*Col+x-1].discOutSumLocal; 
                // get the local discriminator output from western pixel
                if(y==Row-1)  
                    assign pixInf[y*Col+x].discOutSumNear[0] = 1'b0; 
                else 
                    assign pixInf[y*Col+x].discOutSumNear[0] = pixInf[(y+1)*Col+x].discOutSumLocal;   
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

