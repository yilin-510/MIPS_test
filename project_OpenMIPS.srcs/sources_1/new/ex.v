// Description: EX模块：从ID/EX模块得到运算类型alusel_i,运算子类型aluop_i,
//源操作数reg1_i,源操作数reg2_i,要写的目的寄存器地址wd_i,并依据这些数据进行运算

`include "defines.v"

module ex (
    input  wire           rst,

    // 译码阶段送到执行阶段的信息
    input  wire [`AluOpBus]   aluop_i,      // ALU 操作码
    input  wire [`AluSelBus] alusel_i,     // ALU 结果选择
    input  wire [`RegBus]    reg1_i,       // 第一个操作数
    input  wire [`RegBus]    reg2_i,       // 第二个操作数
    input  wire [`RegAddrBus] wd_i,        // 要写的目的寄存器地址
    input  wire             wreg_i,       // 写使能

    // 执行的结果
    output reg [`RegAddrBus] wd_o,
    output reg               wreg_o,
    output reg [`RegBus]     wdata_o
);

// 保存逻辑运算的结果
reg [`RegBus] logicout;

// 第一段：依据 aluop_i 指示的运算子类型进行运算，此处只有逻辑"或"运算
always @(*) begin
    if (rst == `RstEnable) begin
        logicout <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_OR_OP: begin
                logicout <= reg1_i | reg2_i;  // 逻辑"或"运算
            end
            default: begin
                logicout <= `ZeroWord;
            end
        endcase
    end
end

// 第二段：依据 alusel_i 指示的运算类型，选择一个运算结果作为最终结果
always @(*) begin
    wd_o <= wd_i;           // 目的寄存器地址不变
    wreg_o <= wreg_i;       // 写使能不变
    case (alusel_i)
        `EXE_RES_LOGIC: begin
            wdata_o <= logicout;  // 使用逻辑运算结果
        end
        default: begin
            wdata_o <= `ZeroWord;
        end
    endcase
end

endmodule