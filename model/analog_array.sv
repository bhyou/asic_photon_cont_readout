/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../model/analog_array.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 14 Jul 2021 10:33:40 AM CST
 ************************************************************************/
`include "defines.sv"
`include "analog_front_end.sv"
class  analogFrontEndArray #(int Row=3, Col=3);
    
    analog_front_end    analogFE   [Row*Col-1:0];

    function new(virtual sensor_inf  sensorInf[Row*Col-1:0], mailbox mbx[Row*Col-1:0]);
       int coorX, coorY;
       foreach (analogFE[index]) begin
           coorY = $rtoi(index / Col) * 25;
           coorX = (index % Col) * 25;
           analogFE[index] = new(coorX,coorY, mbx[index], sensorInf[index]);
       end
       $display("[info] @analog front end array,the size of array: %0d x %0d", Row, Col);
    endfunction //new()

   task automatic array_reaction();
       real localVol [Row-1:0][Col-1:0];
        for(int idx = 0; idx < Row*Col; idx++) begin
            int pointX = idx / Col;
            int pointY = idx % Col;
            analogFE[idx].get_local_voltage(localVol[pointY][pointX]);
        end

       for (int item = 0; item < Row*Col; item++) begin
           fork
               automatic int index = item;
               automatic int y = index / Col;
               automatic int x = index % Col;
               if((x==Col-1) && (y==0))
                   analogFE[index].hit_reaction(0,0,0,localVol[y][x]);
               else if((x!=Col-1)&&(y==0)) 
                   analogFE[index].hit_reaction(0,localVol[y][x+1],0,localVol[y][x]);
               else if((x==Col) && (y != 0))
                   analogFE[index].hit_reaction(localVol[y-1][x],0,0,localVol[y][x]);
               else
                   analogFE[index].hit_reaction(localVol[y-1][x],localVol[y][x+1],localVol[y-1][x+1],localVol[y][x]);
           join_none
       end
   endtask
endclass //


`ifdef testAnalogFrontEndArray;
`include "generator.sv"
`include "channel.sv"

module testcase;
    parameter Row = 3;
    parameter Col = 3;

    analogFrontEndArray #(.Row(Row),.Col(Col)) feArray;
    generator                                   gen    ;
    channel #(.Row(Row),.Col(Col))              dch    ;

    mailbox             gen2ch;
    mailbox             ch2array [Row*Col-1:0];
    reg                 clk;
    reg                 rst;
    sensor_inf          sensorInf [Row*Col-1:0] (.clock(clk));

    initial begin
        // allocated mailbox        
        gen2ch = new();
        foreach(ch2array[index]) begin 
            ch2array[index] = new ();
        end
        
        // constructed object
        gen = new(gen2ch);
        dch = new(gen2ch,ch2array);
        feArray = new(sensorInf,ch2array);

        gen.hitsNumber = 1;
        fork
            gen.genData();
            dch.transfer();
            feArray.array_reaction();
        join

        #2000;
        $stop;
    end

    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end


endmodule
`endif