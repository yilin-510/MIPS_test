// Description: 流水线的顶层模块：连接所有流水线阶段，协调每个子模块工作

`include "defines.v"

module openmips(
    input  wire           clk,
    input  wire           rst,

    input  wire [`RegBus]   rom_data_i,  // 来自 ROM 的指令数据
    output wire [`RegBus]  rom_addr_o,  // 指向 ROM 的地址
    output wire           rom_ce_o     // ROM 片选信号
);

// 连接 IF/ID 模块与译码阶段 ID 模块的变量
wire [`InstAddrBus] pc;                 // PC 值
wire [`InstAddrBus] id_pc_i;            // 传给 ID 阶段的 PC
wire [`InstBus]     id_inst_i;          // 传给 ID 阶段的指令

// 连接译码阶段 ID 模块输出与 ID/EX 模块的输入的变量
wire [`AluOpBus]    id_aluop_o;         // ALU 操作码
wire [`AluSelBus]   id_alusel_o;        // ALU 结果选择
wire [`RegBus]      id_reg1_o;          // 第一个操作数
wire [`RegBus]      id_reg2_o;          // 第二个操作数
wire               id_wreg_o;           // 写使能
wire [`RegAddrBus]  id_wd_o;            // 目标寄存器地址

// 连接 ID/EX 模块的输出与执行阶段 EX 模块的输入的变量
wire [`AluOpBus]    ex_aluop_i;         // 输入到 EX 的 ALU 操作码
wire [`AluSelBus]   ex_alusel_i;        // 输入到 EX 的 ALU 结果选择
wire [`RegBus]      ex_reg1_i;          // 输入到 EX 的第一个操作数
wire [`RegBus]      ex_reg2_i;          // 输入到 EX 的第二个操作数
wire               ex_wreg_i;           // 输入到 EX 的写使能
wire [`RegAddrBus]  ex_wd_i;            // 输入到 EX 的目标寄存器地址

// 连接执行阶段 EX 模块的输出与 EX/MEM 模块的输入的变量
wire               ex_wreg_o;           // 输出到 EX/MEM 的写使能
wire [`RegAddrBus]  ex_wd_o;            // 输出到 EX/MEM 的目标寄存器地址
wire [`RegBus]      ex_wdata_o;         // 输出到 EX/MEM 的运算结果

// 连接 EX/MEM 模块的输出与 MEM/WB 模块的输入的变量
wire               mem_wreg_i;          // 输入到 MEM 的写使能
wire [`RegAddrBus]  mem_wd_i;           // 输入到 MEM 的目标寄存器地址
wire [`RegBus]      mem_wdata_i;        // 输入到 MEM 的数据

//连接到访存阶段MEM模块的输出与MEM/WB模块的输入的变量
wire               mem_wreg_o;          // 输出到 MEM/WB 的写使能
wire [`RegAddrBus]  mem_wd_o;           // 输出到 MEM/WB 的目标寄存器地址
wire [`RegBus]      mem_wdata_o;        // 输出到 MEM/WB 的数据

// 连接 MEM/WB 模块的输出与回写阶段 WB 模块的输入的变量
wire               wb_wreg_i;           // 输入到 WB 的写使能
wire [`RegAddrBus]  wb_wd_i;            // 输入到 WB 的目标寄存器地址
wire [`RegBus]      wb_wdata_i;         // 输入到 WB 的数据

// 连接译码阶段 ID 模块与通用寄存器 RegFile 模块的变量
wire                reg1_read;          // 读端口 1 使能
wire                reg2_read;          // 读端口 2 使能
wire [`RegBus]      reg1_data;          // 读端口 1 数据
wire [`RegBus]      reg2_data;          // 读端口 2 数据
wire [`RegAddrBus]  reg1_addr;          // 读端口 1 地址
wire [`RegAddrBus]  reg2_addr;          // 读端口 2 地址

// pc_reg 例化
pc_reg pc_reg0(
    .clk(clk),
    .rst(rst),
    .pc(pc),
    .ce(rom_ce_o)
);

assign rom_addr_o = pc;  // 指令存储器的输入地址就是 pc 的值

// IF/ID 模块例化
if_id if_id0(
    .rst(rst),
    .clk(clk),
    .if_pc(pc),
    .if_inst(rom_data_i),
    .id_pc(id_pc_i),
    .id_inst(id_inst_i)
);

// 译码阶段 ID 模块例化
id id0(
    .rst(rst),
    .pc_i(id_pc_i),
    .inst_i(id_inst_i),

    // 来自 regfile 模块的输入
    .reg1_data_i(reg1_data),
    .reg2_data_i(reg2_data),

    // 送到 regfile 模块的信息
    .reg1_read_o(reg1_read),
    .reg2_read_o(reg2_read),
    .reg1_addr_o(reg1_addr),
    .reg2_addr_o(reg2_addr),

    // 送到执行阶段的信息
    .aluop_o(id_aluop_o),
    .alusel_o(id_alusel_o),
    .reg1_o(id_reg1_o),
    .reg2_o(id_reg2_o),
    .wd_o(id_wd_o),
    .wreg_o(id_wreg_o),
      
    //于在 ID 阶段检测是否需要将 EX 阶段刚计算出的结果直接作为操作数
    .ex_wd_i(ex_wd_o),
    .ex_wreg_i(ex_wreg_o),
    .ex_wdata_i(ex_wdata_o),
    
    //用于处理 load 指令等 MEM 阶段才产生结果的情况
    .mem_wd_i(mem_wd_o),
    .mem_wreg_i(mem_wreg_o),
    .mem_wdata_i(mem_wdata_o)
);

// 通用寄存器 regfile 模块例化
regfile regfile0(
    .clk(clk),
    .rst(rst),
    .we(wb_wreg_i),
    .waddr(wb_wd_i),
    .wdata(wb_wdata_i),
    .re1(reg1_read),
    .raddr1(reg1_addr),
    .rdata1(reg1_data),
    .re2(reg2_read),
    .raddr2(reg2_addr),
    .rdata2(reg2_data)
);

// ID/EX 模块例化
id_ex id_ex0(
    .clk(clk),
    .rst(rst),
    
    //从译码阶段ID模块传递过来的信息
    .id_aluop(id_aluop_o),
    .id_alusel(id_alusel_o),
    .id_reg1(id_reg1_o),
    .id_reg2(id_reg2_o),
    .id_wd(id_wd_o),
    .id_wreg(id_wreg_o),
    
    //传递到执行阶段EX模块的信息
    .ex_aluop(ex_aluop_i),
    .ex_alusel(ex_alusel_i),
    .ex_reg1(ex_reg1_i),
    .ex_reg2(ex_reg2_i),
    .ex_wd(ex_wd_i),
    .ex_wreg(ex_wreg_i)
);

// ex 模块例化
ex ex0(
    .rst(rst),
    
    //从ID/EX模块传递过来的信息
    .aluop_i(ex_aluop_i),
    .alusel_i(ex_alusel_i),
    .reg1_i(ex_reg1_i),
    .reg2_i(ex_reg2_i),
    .wd_i(ex_wd_i),
    .wreg_i(ex_wreg_i),
    
    //输出到EX/MEM模块的信息
    .wd_o(ex_wd_o),
    .wreg_o(ex_wreg_o),
    .wdata_o(ex_wdata_o)
);

// EX/MEM 模块例化
ex_mem ex_mem0(
    .clk(clk),
    .rst(rst),
    
    //来自执行阶段EX模块的信息
    .ex_wd(ex_wd_o),
    .ex_wreg(ex_wreg_o),
    .ex_wdata(ex_wdata_o),
    
    //送到访存阶段MEM模块的信息
    .mem_wd(mem_wd_i),
    .mem_wreg(mem_wreg_i),
    .mem_wdata(mem_wdata_i)
);

// MEM 模块例化
mem mem0(
    .rst(rst),
    
    //来自EX/MEM模块的信息
    .wd_i(mem_wd_i),
    .wreg_i(mem_wreg_i),
    .wdata_i(mem_wdata_i),
    
    //送到MEM/WB模块的信息
    .wd_o(mem_wd_o),
    .wreg_o(mem_wreg_o),
    .wdata_o(mem_wdata_o)
);

// MEM/WB 模块例化
mem_wb mem_wb0(
    .clk(clk),
    .rst(rst),
    
    //来自访存阶段MEM模块的信息
    .mem_wd(mem_wd_o),
    .mem_wreg(mem_wreg_o),
    .mem_wdata(mem_wdata_o),
    
    //送到回写阶段的信息
    .wb_wd(wb_wd_i),
    .wb_wreg(wb_wreg_i),
    .wb_wdata(wb_wdata_i)
);

endmodule