//////////////////////////////////////////////////////////////////////
// Module:  ex_mem
// File:    ex_mem.v
// Description: EX/MEM阶段的寄存器
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex_mem(

	input	wire										clk,
	input wire										rst,

	//来自控制模块的信息
	input wire[5:0]							 stall,	
	input wire                   flush,
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_wreg,
	input wire[`RegBus]					 ex_wdata, 	
	input wire[`RegBus]           ex_hi,
	input wire[`RegBus]           ex_lo,
	input wire                    ex_whilo, 	

  //为实现加载、访存指令而添加
  input wire[`AluOpBus]        ex_aluop,
	input wire[`RegBus]          ex_mem_addr,
	input wire[`RegBus]          ex_reg2,

	input wire[`DoubleRegBus]     hilo_i,	
	input wire[1:0]               cnt_i,	

	input wire                   ex_cp0_reg_we,
	input wire[4:0]              ex_cp0_reg_write_addr,
	input wire[`RegBus]          ex_cp0_reg_data,	

  input wire[31:0]             ex_excepttype,
	input wire                   ex_is_in_delayslot,
	input wire[`RegBus]          ex_current_inst_address,
	
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]					 mem_wdata,
	output reg[`RegBus]          mem_hi,
	output reg[`RegBus]          mem_lo,
	output reg                   mem_whilo,

  //为实现加载、访存指令而添加
  output reg[`AluOpBus]        mem_aluop,
	output reg[`RegBus]          mem_mem_addr,
	output reg[`RegBus]          mem_reg2,
	
	output reg                   mem_cp0_reg_we,
	output reg[4:0]              mem_cp0_reg_write_addr,
	output reg[`RegBus]          mem_cp0_reg_data,
	
	output reg[31:0]            mem_excepttype,
  output reg                  mem_is_in_delayslot,
	output reg[`RegBus]         mem_current_inst_address,
		
	output reg[`DoubleRegBus]    hilo_o,
	output reg[1:0]              cnt_o	
	
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
// --- 复位阶段：清空所有输出信号 ---
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;	
		  mem_hi <= `ZeroWord;
		  mem_lo <= `ZeroWord;
		  mem_whilo <= `WriteDisable;		
	    hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	
  		mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;	
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;	
			mem_excepttype <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
	    mem_current_inst_address <= `ZeroWord;
		end else if(flush == 1'b1 ) begin
// --- 冲刷阶段：当异常发生时，向 MEM 阶段传递 NOP (空操作) ---
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;
		  mem_hi <= `ZeroWord;
		  mem_lo <= `ZeroWord;
		  mem_whilo <= `WriteDisable;
  		mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			mem_excepttype <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
	    mem_current_inst_address <= `ZeroWord;
	    hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	    	    				
		end else if(stall[3] == `Stop && stall[4] == `NoStop) begin
// --- 暂停逻辑 1：EX阶段停止，但 MEM阶段继续 ---
// 这种情况下，EX/MEM 寄存器需要向 MEM 阶段打入一个"气泡"(Bubble/NOP)
// 避免 MEM 阶段重复执行同一条指令
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  mem_wdata <= `ZeroWord;
		  mem_hi <= `ZeroWord;
		  mem_lo <= `ZeroWord;
		  mem_whilo <= `WriteDisable;
// 重点：乘加/乘减指令的中间结果 (hilo_i) 必须保持，否则多周期运算会丢失数据
	    hilo_o <= hilo_i;
			cnt_o <= cnt_i;	
  		mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;		
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;	
			mem_excepttype <= `ZeroWord;
			mem_is_in_delayslot <= `NotInDelaySlot;
	    mem_current_inst_address <= `ZeroWord;						  				    
		end else if(stall[3] == `NoStop) begin
// --- 正常流动：EX 阶段不停止 ---
// 将 EX 阶段的所有计算结果、写寄存器地址、CP0控制信号等同步到 MEM 阶段
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;	
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;
			mem_whilo <= ex_whilo;	
// 正常流动时，hilo 临时结果不需要跨级传递，设为 0
	    hilo_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;	
// 为访存指令准备的地址和数据
  		mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;
			mem_cp0_reg_we <= ex_cp0_reg_we;
			mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			mem_cp0_reg_data <= ex_cp0_reg_data;
// 异常相关信息传递	
			mem_excepttype <= ex_excepttype;
			mem_is_in_delayslot <= ex_is_in_delayslot;
	    mem_current_inst_address <= ex_current_inst_address;						
		end else begin
// --- 暂停逻辑 2：EX 和 MEM 同时停止 ---
// 此时寄存器保持原值，hilo 中间结果继续维持
	    hilo_o <= hilo_i;
			cnt_o <= cnt_i;											
		end    //if
	end      //always
			

endmodule