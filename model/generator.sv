/*************************************************************************
 > Copyright (C) 2021 Sangfor Ltd. All rights reserved.
 > File Name   : generator.svh
 > Author      : bhyou
 > Mail        : bhyou@foxmail.com 
 > Created Time: Fri 09 Jul 2021 10:46:48 AM CST
 ************************************************************************/
 //`include "photon.sv"
class generator;
   //declare variables in this region
   mailbox mbx       ;
   int     hitsNumber;   // the number of hits
   event   drvDone   ;

   function new(mailbox mbx);
      this.mbx = mbx;
   endfunction //new()

   task automatic genData();
      photon hits = new();

      repeat(hitsNumber) begin
         hits.randomize() with { addrX == 25; addrY == 25;};
         hits.print();
         mbx.put(hits);
     //    @(drvDone);
      end
   endtask
endclass // generator