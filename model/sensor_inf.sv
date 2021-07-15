/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../model/sensor_inf.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Thu 15 Jul 2021 09:48:27 AM CST
 ************************************************************************/
interface sensor_inf ( input bit clock);
    logic discOutLocal;
    logic discOutSum;

    task local_discriminate(int duty);
        if((duty <= 100) && (duty >= 0)) begin 
            discOutLocal = 1'b0;
            repeat(50-duty/2)  @(edge clock);

            discOutLocal = 1'b1;
            repeat(duty)   @(edge clock);

            discOutLocal = 1'b0;
            repeat(50-duty/2) @(edge clock);
        end
        else begin
            $fatal("the range of in-parameter duty is 0~100");
        end
    endtask

    task summing_discriminate(int duty);
        if((duty <= 100) && (duty >= 0)) begin 
            discOutSum = 1'b0;
            repeat(50-duty/2)  @(edge clock);

            discOutSum = 1'b1;
            repeat(duty)   @(edge clock);

            discOutSum = 1'b0;
            repeat(50-duty/2)  @(edge clock);
        end
        else begin
            $fatal("the range of in-parameter duty is 0~100");
        end
    endtask

endinterface //sensor_inf