`include "defines.v"
module openmips_min_sopc(
    input   wire            clk,
    input   wire            rst,
    output  wire [7:0]      seg_data_0_pin, // 段选
    output  wire [7:0]      seg_cs_pin  // 位选 (对应约束中的 1_pin)
);

    // 内部信号
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
    
    assign int = {5'b00000, timer_int};

    // 实例化 CPU
    openmips openmips0(
        .clk(clk), .rst(rst),
        .rom_addr_o(inst_addr), .rom_data_i(inst), .rom_ce_o(rom_ce),
        .int_i(int),
        .ram_we_o(mem_we_i), .ram_addr_o(mem_addr_i), .ram_sel_o(mem_sel_i),
        .ram_data_o(mem_data_i), .ram_data_i(mem_data_o), .ram_ce_o(mem_ce_i),
        .timer_int_o(timer_int)
    );

    // 实例化 ROM
    inst_rom inst_rom0(
        .ce(rom_ce), .addr(inst_addr), .inst(inst)
    );

    // 实例化 RAM
    data_ram data_ram0(
        .clk(clk), .ce(mem_ce_i), .we(mem_we_i), .addr(mem_addr_i),
        .sel(mem_sel_i), .data_i(mem_data_i), .data_o(mem_data_o)
    );

    // --- 新增：显示寄存器 ---
    // 当 CPU 往内存写数据时，如果是我们约定的地址，就存入显示寄存器
    reg [31:0] display_reg;
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            display_reg <= 32'h88888888;
        end else if (mem_ce_i && mem_we_i) begin
            display_reg <= mem_data_i; // 捕获 CPU 写入的数据
        end
    end

    // 实例化数码管驱动
    // 注意：将 seg_data_0_pin 作为段选，seg_cs_pin 作为位选
    seg_driver seg_driver0(
        .clk(clk), .rst(rst),
        .data_in(display_reg),
        .seg_o(seg_data_0_pin),
        .dig_en_o(seg_cs_pin)
    );

endmodule
