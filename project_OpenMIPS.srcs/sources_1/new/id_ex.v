// Description: ID/EX模块：将译码阶段取得的运算类型，源操作数，要写的目的寄存器地址等结果，
//在下一个时钟传递到流水线执行阶段

`include "defines.v"

module id_ex (
    input  wire           clk,
    input  wire           rst,

    // 从译码阶段传递过来的信息
    input  wire [`AluOpBus]   id_aluop,     // ALU 操作码
    input  wire [`AluSelBus] id_alusel,    // ALU 结果选择
    input  wire [`RegBus]    id_reg1,      // 第一个操作数
    input  wire [`RegBus]    id_reg2,      // 第二个操作数
    input  wire [`RegAddrBus] id_wd,       // 目标寄存器地址
    input  wire             id_wreg,      // 写使能

    // 传送到执行阶段的信息
    output reg [`AluOpBus]   ex_aluop,
    output reg [`AluSelBus]  ex_alusel,
    output reg [`RegBus]     ex_reg1,
    output reg [`RegBus]     ex_reg2,
    output reg [`RegAddrBus] ex_wd,
    output reg               ex_wreg
);

always @(posedge clk) begin
    if (rst == `RstEnable) begin
        ex_aluop <= `EXE_NOP_OP;
        ex_alusel <= `EXE_RES_NOP;
        ex_reg1 <= `ZeroWord;
        ex_reg2 <= `ZeroWord;
        ex_wd <= `NOPRegAddr;
        ex_wreg <= `WriteDisable;
    end else begin
        ex_aluop <= id_aluop;
        ex_alusel <= id_alusel;
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_wd <= id_wd;
        ex_wreg <= id_wreg;
    end
end

endmodule
