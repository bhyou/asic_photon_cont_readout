/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../model/analog_env.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 14 Jul 2021 03:21:05 PM CST
 ************************************************************************/
 `include "defines.sv"
 `include "analog_array.sv"
 `include "generator.sv"
 `include "channel.sv"

 class analog_environment #(int Row=2, Col=2);

    generator             gen;
    channel #(Row, Col)              dch;  // data channel
    analogFrontEndArray #(Row, Col)  aa ; 

    virtual sensor_inf    sensorInf [Row*Col-1:0];
    mailbox               ch2array [Row*Col-1:0];
    mailbox               gen2ch   ;

    function new(virtual sensor_inf sensorInf[Row*Col-1:0]);
        this.sensorInf = sensorInf;
    endfunction //new()


    task connect();
        // allocated mailbox
        gen2ch = new();
        foreach(ch2array[index]) begin 
            ch2array[index] = new ();
        end

        // allocated object
        gen = new(gen2ch);
        dch = new(gen2ch,ch2array);
        aa  = new(sensorInf,ch2array);
    endtask

    task automatic pre_test(int photons);
        gen.hitsNumber = photons;
    endtask

    task automatic test();
        fork
            gen.genData();
            dch.transfer();
            aa.array_reaction();
        join
    endtask //automatic

    task automatic post_test();
        #2000;
        $stop;
    endtask //automatic

 endclass //analog_environment

 `ifdef testAnalogEnvironment

 module  analogEnv_tb;
    parameter Row = 4;
    parameter Col = 4;

    reg      clock;
    analog_environment#(Row,Col) analogEnv ;
    sensor_inf                   sensorInf [Row*Col-1:0] (clock);

    initial begin
        analogEnv = new(sensorInf);

        repeat(2) begin 
            analogEnv.connect();
            analogEnv.pre_test(1);
            analogEnv.test();
            #20;
        end
            analogEnv.post_test();
    end
 endmodule
 `endif