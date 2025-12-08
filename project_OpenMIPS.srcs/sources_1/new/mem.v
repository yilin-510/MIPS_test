// Description: MEM模块

`include "defines.v"

module mem (
    input  wire           rst,

    // 来自执行阶段的信息
    input  wire [`RegAddrBus] wd_i,       // 要写的目的寄存器地址
    input  wire             wreg_i,      // 写使能
    input  wire [`RegBus]   wdata_i,    // 要写的数据

    // 访存阶段的结果
    output reg [`RegAddrBus] wd_o,
    output reg               wreg_o,
    output reg [`RegBus]     wdata_o
);

always @(*) begin
    if (rst == `RstEnable) begin
        wd_o <= `NOPRegAddr;
        wreg_o <= `WriteDisable;
        wdata_o <= `ZeroWord;
    end else begin
        wd_o <= wd_i;
        wreg_o <= wreg_i;
        wdata_o <= wdata_i;
    end
end

endmodule