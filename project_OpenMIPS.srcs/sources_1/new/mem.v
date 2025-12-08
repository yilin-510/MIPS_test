// Description: MEM模块：访存阶段（在本设计中无实际访存操作，仅直通数据到回写阶段）

`include "defines.v"

module mem (
    input  wire           rst,

    // 来自执行阶段（EX）的信息（经 EX/MEM 寄存器传递）
    input  wire [`RegAddrBus] wd_i,        // 目标寄存器地址（rd/rt）
    input  wire               wreg_i,      // 是否写回通用寄存器
    input  wire [`RegBus]     wdata_i,     // 运算结果（ALU 或移动指令输出）
    input  wire [`RegBus]     hi_i,        // 执行阶段产生的 HI 值（如 MTHI）
    input  wire [`RegBus]     lo_i,        // 执行阶段产生的 LO 值（如 MTLO）
    input  wire               whilo_i,     // 是否需要在本周期写 HI/LO

    // 输出到回写阶段（WB）的信息
    output reg [`RegAddrBus] wd_o,         // 目标寄存器地址（直通）
    output reg               wreg_o,       // 写使能（直通）
    output reg [`RegBus]     wdata_o,      // 数据（直通）
    output reg [`RegBus]     hi_o,         // HI 值（用于 WB 阶段前递）
    output reg [`RegBus]     lo_o,         // LO 值（用于 WB 阶段前递）
    output reg               whilo_o       // 是否在 WB 阶段写 HI/LO
);

always @ (*) begin
    if (rst == `RstEnable) begin
        wd_o      <= `NOPRegAddr;
        wreg_o    <= `WriteDisable;
        wdata_o   <= `ZeroWord;
        hi_o      <= `ZeroWord;
        lo_o      <= `ZeroWord;
        whilo_o   <= `WriteDisable;
    end else begin
        wd_o      <= wd_i;
        wreg_o    <= wreg_i;
        wdata_o   <= wdata_i;
        hi_o      <= hi_i;
        lo_o      <= lo_i;
        whilo_o   <= whilo_i;
    end  // if
end      // always

endmodule