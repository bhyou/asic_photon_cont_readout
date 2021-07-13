/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : analog_front_end.svh
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: 2021年06月22日 星期二 14时48分20秒
 ************************************************************************/

//-------------------------------------------------------------
//  function:
//   describe particle hit response, such as collect energy, 
//   shaper (convert collected energy to voltage), compator (over
//   -threshold comparetor), then output a pulse to digital front-end 
//   of pixel cell
//--------------------------------------------------------------
`include "discriminator.sv"
`include "sensor.sv"

`ifdef testingAnalogFrontend
    `include "defines.sv"
    `include "generator.sv"
`endif

class analog_front_end;
    sensor             sensor ;
    discriminator      disc;

    function new(int coorX, coorY, mailbox mbx, virtual sensor_inf sensorInf);
        sensor = new(coorX, coorY, mbx);
        disc = new(sensorInf);
    endfunction //new()

    task automatic hit_reaction(real voltageS, voltageE, voltageSE, real localVoltage);
        sensor.convert_energy_to_voltage(localVoltage);
        fork
            disc.local_compare(localVoltage);
            disc.summing_compare(localVoltage,voltageS, voltageE,voltageSE);
        join
    endtask // 
endclass //analog_front_end

`ifdef testingAnalogFrontend
module testcase;
    reg    clock;
    wire   discOutLocal;
    wire   discOutSum;
    real   localVoltage;

    mailbox           mbx;
    generator         Gen;
    analog_front_end  aFE;
    sensor_inf sensorInf (clock);

    assign discOutSum   = sensorInf.discOutSum;
    assign discOutLocal = sensorInf.discOutLocal;


    initial begin
        clock = 1'b0;
        forever begin
            #1 clock = ~clock;
        end
    end

    initial begin
        mbx = new();
        Gen = new(mbx);
        aFE = new(25, 25, mbx, sensorInf);
        Gen.hitsNumber = 1;

        fork
            Gen.genData();
            aFE.hit_reaction(20,10,30,localVoltage);
        join
        $stop;
    end

endmodule
`endif