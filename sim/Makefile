##########################################################################
# Copyright (C) 2021 Sangfor Ltd. All rights reserved.
# File Name   : Makefile
# Author      : bhyou
# mail        : bhyou@foxmail.com
# Created Time: Thu 24 Jun 2021 03:36:49 PM CST
#########################################################################
.PHONY:clean file com mixed sim 
clean:
	@rm -fr simv* csrc* ucli* 64 AN* DVE* *.vpd  *.log
	@rm -fr .restart* .synopsys*

#The following compile option is used for coverage.
coverOpt += -cm line+cond+tgl+fsm+branch+assert
#The following compile option is used to interactive simulation on verdi and vcs
comOpt += -lca -kdb
comOpt += -full64 -sverilog +v2k 
comOpt += -override_timescale=1ns/1ps
logOpt += -l vcs_run.log

wavefile = vpd
ifeq ($(wavefile),vpd)
	macroOpt += +define+VPD
	comOpt += -debug_pp
else
	comOpt += -fsdb
endif

macroOpt += +define+DEBUG_MEDIUM=1
macroOpt += +incdir+../model+../bench

top ?= top_tb
simOpt += -l tb_sim.log 

useList  = 0
ifeq ($(useList), 1)
	FILES    = -file $(filelist) 
	filelist = vloglist.f
else
	FILES  = hello.v
endif

file:
	@touch vloglist.f
	@find .. -name "*.*v" > vloglist.f
ifneq ($(wildcard ../*/*.vhd),)
	@find .. -name  "*.vhd" > vhdllist.f 
endif

com:
	vcs $(comOpt) $(logOpt) $(macroOpt) $(FILES) $(TOP)


#The following three steps are used for vhdl-verilog mixed simulation.
#The first two steps is used to analyse hdl coding.
#The third step is used to elaborate the coding.
mixed:filelist
	vhdlan -fulll64 -nc vhdlist.f
	vlogan -full64 +v2k -sverilog +define+syn_off vloglist.f 
	vcs -full64 -debug_pp -top $(top) -l elab.log $(comOpt)
cov:
	@./simv $(simOpt) $(coverOpt) 

dve:
	@./simv $(simOpt) -gui & 

verdi:
	@./simv $(simOpt) -gui=verdi & 

view:
	dve -full64 -covdir simv.vdb 
# view fsdb cmd: verdi -nologo -ssf *.fsdb 
# view coverage report cmd: dve -full64 -cov -dir simv.vpd

