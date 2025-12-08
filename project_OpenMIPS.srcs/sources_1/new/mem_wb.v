// Description: MEM/WB模块：将访存阶段的运算结果，在下一个时钟传递到写回阶段

`include "defines.v"

module mem_wb (
    input  wire           clk,
    input  wire           rst,

    // 来自访存阶段（MEM）的信息
    input  wire [`RegAddrBus] mem_wd,        // 目标寄存器地址（rd/rt）
    input  wire               mem_wreg,      // 是否写回通用寄存器
    input  wire [`RegBus]     mem_wdata,     // 运算或加载的数据
    input  wire [`RegBus]     mem_hi,        // MEM 阶段产生的 HI 值（如来自 MTHI）
    input  wire [`RegBus]     mem_lo,        // MEM 阶段产生的 LO 值（如来自 MTLO）
    input  wire               mem_whilo,     // MEM 阶段是否要写 HI/LO

    // 输出到写回阶段（WB）的信息（打一拍）
    output reg [`RegAddrBus] wb_wd,          // 目标寄存器地址（直通）
    output reg               wb_wreg,        // 写使能（直通）
    output reg [`RegBus]     wb_wdata,       // 数据（直通）
    output reg [`RegBus]     wb_hi,          // HI 值（供 WB 阶段写入 HILO_REG）
    output reg [`RegBus]     wb_lo,          // LO 值（供 WB 阶段写入 HILO_REG）
    output reg               wb_whilo        // 是否在 WB 阶段写 HI/LO
);

always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        wb_wd      <= `NOPRegAddr;
        wb_wreg    <= `WriteDisable;
        wb_wdata   <= `ZeroWord;
        wb_hi      <= `ZeroWord;
        wb_lo      <= `ZeroWord;
        wb_whilo   <= `WriteDisable;
    end else begin
        wb_wd      <= mem_wd;
        wb_wreg    <= mem_wreg;
        wb_wdata   <= mem_wdata;
        wb_hi      <= mem_hi;
        wb_lo      <= mem_lo;
        wb_whilo   <= mem_whilo;
    end  // if
end      // always

endmodule