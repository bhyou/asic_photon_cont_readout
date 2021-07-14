/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : ../model/channel.sv
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Wed 14 Jul 2021 09:56:21 AM CST
 > function    : a data transmit channel
    receive a photon event and then transfer it to all pixel in the array
 ************************************************************************/
`include "defines.sv"
`include "photon.sv"
class channel #(int Row=2, Col=2);

    mailbox     receiveMbx;
    mailbox     transmitMbx[Row*Col-1:0];
    
    function new(mailbox in_mbx, mailbox out_mbx[Row*Col-1:0]);
        this.receiveMbx = in_mbx;
        this.transmitMbx = out_mbx;
    endfunction

    task transfer();
        photon trns;
        receiveMbx.get(trns);

        foreach(transmitMbx[index])
            transmitMbx[index].put(trns.copy());
    endtask
endclass

`ifdef testingChannel
`include "generator.sv"

program testcase;
    parameter       Col = 2;
    parameter       Row = 2;

    generator       gen;
    channel         dch;
    mailbox         gen2ch;
    mailbox         ch2array [];

    photon          pkt [];

    initial begin
        ch2array = new[Row*Col];
        pkt      = new[Row*Col];

        // constructed mailbox
        gen2ch = new();
        foreach(ch2array[index]) begin 
            ch2array[index] = new();
        end
        // allocated generator and channel
        gen = new(gen2ch);
        dch = new(gen2ch,ch2array);


        gen.hitsNumber = 1;

        $display("finished initial");
        fork
            gen.genData();
            dch.transfer();
            getPacket(0);
            getPacket(1);
            getPacket(2);
            getPacket(3);
        join


        #100;
    end

    task getPacket(int x);
        ch2array[x].get(pkt[x]);
        pkt[x].print();
    endtask

endprogram
`endif
