// Final Top Module for EG01 Board: Displaying Fibonacci Result from $s0
`include "defines.v"

module openmips_min_sopc(
	input	wire										clk,
	input wire										rst,
	
	// 数码管接口
	output wire [7:0]               seg_o,
	output wire [3:0]               dig_en_o,
	// LED 接口
	output wire [15:0]              led_o
);

  wire[`InstAddrBus] inst_addr;
  wire[`InstBus] inst;
  wire rom_ce;
  wire mem_we_i;
  wire[`RegBus] mem_addr_i;
  wire[`RegBus] mem_data_i;
  wire[`RegBus] mem_data_o;
  wire[3:0] mem_sel_i; 
  wire mem_ce_i;   
  wire[5:0] int;
  wire timer_int;
  wire[`RegBus] s0_data; // 用于接收 $s0 的值

  assign int = {5'b00000, timer_int};

  openmips openmips0(
		.clk(clk),
		.rst(rst),
		.rom_addr_o(inst_addr),
		.rom_data_i(inst),
		.rom_ce_o(rom_ce),
        .int_i(int),
		.ram_we_o(mem_we_i),
		.ram_addr_o(mem_addr_i),
		.ram_sel_o(mem_sel_i),
		.ram_data_o(mem_data_i),
		.ram_data_i(mem_data_o),
		.ram_ce_o(mem_ce_i),
		.timer_int_o(timer_int),
        .s0_data_o(s0_data) // 连接 $s0 数据
	);
	
	inst_rom inst_rom0(
		.ce(rom_ce),
		.addr(inst_addr),
		.inst(inst)	
	);

	data_ram data_ram0(
		.clk(clk),
		.ce(mem_ce_i),
		.we(mem_we_i),
		.addr(mem_addr_i),
		.sel(mem_sel_i),
		.data_i(mem_data_i),
		.data_o(mem_data_o)	
	);

	// 实例化数码管驱动：现在显示的是 $s0 的值（斐波那契计算结果）
	seg_driver seg_driver0(
		.clk(clk),
		.rst(rst),
		.data_in(s0_data),
		.seg_o(seg_o),
		.dig_en_o(dig_en_o)
	);

	// LED 显示 PC 地址，作为运行状态参考
	assign led_o = inst_addr[15:0];

endmodule
