// Description: EX/MEM模块：将执行阶段取得的运算结果，在下一个时钟传递到流水线访存阶段

`include "defines.v"

module ex_mem (
    input  wire           clk,
    input  wire           rst,

    // 来自执行阶段（EX）的信息
    input  wire [`RegAddrBus] ex_wd,        // 目标寄存器地址（rd/rt）
    input  wire               ex_wreg,      // 是否写回通用寄存器
    input  wire [`RegBus]     ex_wdata,     // ALU 或移动指令的运算结果
    input  wire [`RegBus]     ex_hi,        // 执行阶段产生的 HI 值（用于 MTHI 等）
    input  wire [`RegBus]     ex_lo,        // 执行阶段产生的 LO 值（用于 MTLO 等）
    input  wire               ex_whilo,     // 执行阶段是否要写 HI/LO 寄存器

    // 送往访存阶段（MEM）的信息（打一拍）
    output reg [`RegAddrBus] mem_wd,        // 目标寄存器地址（直通）
    output reg               mem_wreg,      // 写使能（直通）
    output reg [`RegBus]     mem_wdata,     // 运算结果（直通）
    output reg [`RegBus]     mem_hi,        // HI 值（用于 MEM 阶段前递）
    output reg [`RegBus]     mem_lo,        // LO 值（用于 MEM 阶段前递）
    output reg               mem_whilo      // 是否在 MEM 阶段写 HI/LO
);

always @(posedge clk) begin
    if (rst == `RstEnable) begin
        mem_wd      <= `NOPRegAddr;
        mem_wreg    <= `WriteDisable;
        mem_wdata   <= `ZeroWord;
        mem_hi      <= `ZeroWord;
        mem_lo      <= `ZeroWord;
        mem_whilo   <= `WriteDisable;
    end else begin
        mem_wd      <= ex_wd;
        mem_wreg    <= ex_wreg;
        mem_wdata   <= ex_wdata;
        mem_hi      <= ex_hi;
        mem_lo      <= ex_lo;
        mem_whilo   <= ex_whilo;
    end
end

endmodule