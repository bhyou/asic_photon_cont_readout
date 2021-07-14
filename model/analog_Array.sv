/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../model/analog_Array.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 14 Jul 2021 10:33:40 AM CST
 ************************************************************************/

 class  analogFrontEndArray #(int Row=2, Col=2);

    analog_front_end    analogFE   [Row*Col-1:0];

    function new(sensor_inf sensorInf[Row*Col-1:0], mailbox mbx[Row*Col-1:0]);
        int coorX, coorY;
        foreach (analogFE[index]) begin
            coorY = $rtoi(index / Col);
            coorX = index % Col;
            analogFE[i] = new(cooX,coorY, mbx[index], sensorInf[index]);
        end
    endfunction //new()

    task automatic array_reaction();
        real localVol [Row-1:0][Col-1:0];
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
            join
        end
    endtask
 endclass //