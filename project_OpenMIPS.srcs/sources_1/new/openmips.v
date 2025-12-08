`include "defines.v"

module openmips (
    input  wire           clk,
    input  wire           rst,

    // 指令存储器接口
    input  wire [`RegBus] rom_data_i,   // 从 ROM 读取的指令
    output wire [`RegBus] rom_addr_o,   // 输出到 ROM 的地址（即 PC）
    output wire           rom_ce_o      // ROM 片选信号（始终使能）
);

// ----------------------------
// 内部信号声明
// ----------------------------

// PC 相关
wire [`InstAddrBus] pc;          // 当前取指地址
wire [`InstAddrBus] id_pc_i;     // ID 阶段看到的 PC（用于异常等）
wire [`InstBus]     id_inst_i;   // ID 阶段的指令

// ID 阶段输出 -> ID/EX 寄存器输入
wire [`AluOpBus]    id_aluop_o;
wire [`AluSelBus]   id_alusel_o;
wire [`RegBus]      id_reg1_o;
wire [`RegBus]      id_reg2_o;
wire                id_wreg_o;
wire [`RegAddrBus]  id_wd_o;

// ID/EX 寄存器输出 -> EX 阶段输入
wire [`AluOpBus]    ex_aluop_i;
wire [`AluSelBus]   ex_alusel_i;
wire [`RegBus]      ex_reg1_i;
wire [`RegBus]      ex_reg2_i;
wire                ex_wreg_i;
wire [`RegAddrBus]  ex_wd_i;

// EX 阶段输出 -> EX/MEM 寄存器输入
wire                ex_wreg_o;
wire [`RegAddrBus]  ex_wd_o;
wire [`RegBus]      ex_wdata_o;
wire [`RegBus]      ex_hi_o;
wire [`RegBus]      ex_lo_o;
wire                ex_whilo_o;

// EX/MEM 寄存器输出 -> MEM 阶段输入
wire                mem_wreg_i;
wire [`RegAddrBus]  mem_wd_i;
wire [`RegBus]      mem_wdata_i;
wire [`RegBus]      mem_hi_i;
wire [`RegBus]      mem_lo_i;
wire                mem_whilo_i;

// MEM 阶段输出 -> MEM/WB 寄存器输入
wire                mem_wreg_o;
wire [`RegAddrBus]  mem_wd_o;
wire [`RegBus]      mem_wdata_o;
wire [`RegBus]      mem_hi_o;
wire [`RegBus]      mem_lo_o;
wire                mem_whilo_o;

// MEM/WB 寄存器输出 -> WB 阶段（写回）
wire                wb_wreg_i;
wire [`RegAddrBus]  wb_wd_i;
wire [`RegBus]      wb_wdata_i;
wire [`RegBus]      wb_hi_i;
wire [`RegBus]      wb_lo_i;
wire                wb_whilo_i;

// Regfile 接口
wire                reg1_read;
wire                reg2_read;
wire [`RegBus]      reg1_data;
wire [`RegBus]      reg2_data;
wire [`RegAddrBus]  reg1_addr;
wire [`RegAddrBus]  reg2_addr;

// HI/LO 寄存器当前值
wire [`RegBus]      hi;
wire [`RegBus]      lo;

// ----------------------------
// 模块实例化
// ----------------------------

// PC 寄存器（IF 阶段）
pc_reg pc_reg0 (
    .clk (clk),
    .rst (rst),
    .pc  (pc),
    .ce  (rom_ce_o)
);
assign rom_addr_o = pc;  // PC 直接作为 ROM 地址输出
assign rom_ce_o   = 1'b1; // 假设 ROM 始终使能（可根据需要调整）

// IF/ID 流水线寄存器
if_id if_id0 (
    .clk      (clk),
    .rst      (rst),
    .if_pc    (pc),
    .if_inst  (rom_data_i),
    .id_pc    (id_pc_i),
    .id_inst  (id_inst_i)
);

// 译码阶段（ID）
id id0 (
    .rst            (rst),
    .pc_i           (id_pc_i),
    .inst_i         (id_inst_i),

    // 通用寄存器读数据
    .reg1_data_i    (reg1_data),
    .reg2_data_i    (reg2_data),

    // 前递：来自 EX 阶段的写回信息
    .ex_wreg_i      (ex_wreg_o),
    .ex_wdata_i     (ex_wdata_o),
    .ex_wd_i        (ex_wd_o),

    // 前递：来自 MEM 阶段的写回信息
    .mem_wreg_i     (mem_wreg_o),
    .mem_wdata_i    (mem_wdata_o),
    .mem_wd_i       (mem_wd_o),

    // 控制 Regfile 读端口
    .reg1_read_o    (reg1_read),
    .reg2_read_o    (reg2_read),
    .reg1_addr_o    (reg1_addr),
    .reg2_addr_o    (reg2_addr),

    // 输出到 ID/EX 寄存器
    .aluop_o        (id_aluop_o),
    .alusel_o       (id_alusel_o),
    .reg1_o         (id_reg1_o),
    .reg2_o         (id_reg2_o),
    .wd_o           (id_wd_o),
    .wreg_o         (id_wreg_o)
);

// 通用寄存器堆（Regfile）
regfile regfile1 (
    .clk     (clk),
    .rst     (rst),
    .we      (wb_wreg_i),     // 写使能（来自 WB 阶段）
    .waddr   (wb_wd_i),       // 写地址
    .wdata   (wb_wdata_i),    // 写数据
    .re1     (reg1_read),      // 读使能1
    .raddr1  (reg1_addr),     // 读地址1
    .rdata1  (reg1_data),     // 读数据1
    .re2     (reg2_read),      // 读使能2
    .raddr2  (reg2_addr),     // 读地址2
    .rdata2  (reg2_data)      // 读数据2
);

// ID/EX 流水线寄存器
id_ex id_ex0 (
    .clk        (clk),
    .rst        (rst),

    // 来自 ID 阶段
    .id_aluop   (id_aluop_o),
    .id_alusel  (id_alusel_o),
    .id_reg1    (id_reg1_o),
    .id_reg2    (id_reg2_o),
    .id_wd      (id_wd_o),
    .id_wreg    (id_wreg_o),

    // 送往 EX 阶段
    .ex_aluop   (ex_aluop_i),
    .ex_alusel  (ex_alusel_i),
    .ex_reg1    (ex_reg1_i),
    .ex_reg2    (ex_reg2_i),
    .ex_wd      (ex_wd_i),
    .ex_wreg    (ex_wreg_i)
);

// 执行阶段（EX）
ex ex0 (
    .rst          (rst),

    // 来自 ID/EX
    .aluop_i      (ex_aluop_i),
    .alusel_i     (ex_alusel_i),
    .reg1_i       (ex_reg1_i),
    .reg2_i       (ex_reg2_i),
    .wd_i         (ex_wd_i),
    .wreg_i       (ex_wreg_i),

    // 当前 HI/LO 值
    .hi_i         (hi),
    .lo_i         (lo),

    // 前递：WB 阶段对 HI/LO 的写
    .wb_hi_i      (wb_hi_i),
    .wb_lo_i      (wb_lo_i),
    .wb_whilo_i   (wb_whilo_i),

    // 前递：MEM 阶段对 HI/LO 的写
    .mem_hi_i     (mem_hi_o),
    .mem_lo_i     (mem_lo_o),
    .mem_whilo_i  (mem_whilo_o),

    // 输出到 EX/MEM
    .wd_o         (ex_wd_o),
    .wreg_o       (ex_wreg_o),
    .wdata_o      (ex_wdata_o),
    .hi_o         (ex_hi_o),
    .lo_o         (ex_lo_o),
    .whilo_o      (ex_whilo_o)
);

// EX/MEM 流水线寄存器
ex_mem ex_mem0 (
    .clk        (clk),
    .rst        (rst),

    // 来自 EX
    .ex_wd      (ex_wd_o),
    .ex_wreg    (ex_wreg_o),
    .ex_wdata   (ex_wdata_o),
    .ex_hi      (ex_hi_o),
    .ex_lo      (ex_lo_o),
    .ex_whilo   (ex_whilo_o),

    // 送往 MEM
    .mem_wd     (mem_wd_i),
    .mem_wreg   (mem_wreg_i),
    .mem_wdata  (mem_wdata_i),
    .mem_hi     (mem_hi_i),
    .mem_lo     (mem_lo_i),
    .mem_whilo  (mem_whilo_i)
);

// 访存阶段（MEM）-- 本设计中无实际访存，仅直通
mem mem0 (
    .rst        (rst),

    // 来自 EX/MEM
    .wd_i       (mem_wd_i),
    .wreg_i     (mem_wreg_i),
    .wdata_i    (mem_wdata_i),
    .hi_i       (mem_hi_i),
    .lo_i       (mem_lo_i),
    .whilo_i    (mem_whilo_i),

    // 送往 MEM/WB
    .wd_o       (mem_wd_o),
    .wreg_o     (mem_wreg_o),
    .wdata_o    (mem_wdata_o),
    .hi_o       (mem_hi_o),
    .lo_o       (mem_lo_o),
    .whilo_o    (mem_whilo_o)
);

// MEM/WB 流水线寄存器
mem_wb mem_wb0 (
    .clk        (clk),
    .rst        (rst),

    // 来自 MEM
    .mem_wd     (mem_wd_o),
    .mem_wreg   (mem_wreg_o),
    .mem_wdata  (mem_wdata_o),
    .mem_hi     (mem_hi_o),
    .mem_lo     (mem_lo_o),
    .mem_whilo  (mem_whilo_o),

    // 送往 WB（写回）
    .wb_wd      (wb_wd_i),
    .wb_wreg    (wb_wreg_i),
    .wb_wdata   (wb_wdata_i),
    .wb_hi      (wb_hi_i),
    .wb_lo      (wb_lo_i),
    .wb_whilo   (wb_whilo_i)
);

// HI/LO 专用寄存器
hilo_reg hilo_reg0 (
    .clk    (clk),
    .rst    (rst),

    // 写端口（来自 WB 阶段）
    .we     (wb_whilo_i),
    .hi_i   (wb_hi_i),
    .lo_i   (wb_lo_i),

    // 读端口（供 EX 阶段使用）
    .hi_o   (hi),
    .lo_o   (lo)
);

endmodule