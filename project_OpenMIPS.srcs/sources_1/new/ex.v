// Description: EX模块：从ID/EX模块得到运算类型alusel_i,运算子类型aluop_i,
// 源操作数reg1_i,源操作数reg2_i,要写的目的寄存器地址wd_i,并依据这些数据进行运算

`include "defines.v"

module ex (
    input  wire           rst,

    // 译码阶段送到执行阶段的信息
    input  wire [`AluOpBus]   aluop_i,      // ALU 操作码（具体运算类型）
    input  wire [`AluSelBus]  alusel_i,     // ALU 结果选择（逻辑 or 移位）
    input  wire [`RegBus]     reg1_i,       // 第一个操作数（如 rs 或 shamt）
    input  wire [`RegBus]     reg2_i,       // 第二个操作数（如 rt 或立即数）
    input  wire [`RegAddrBus] wd_i,         // 要写回的目的寄存器地址
    input  wire               wreg_i,       // 写使能信号（是否需要写回）

    // 执行阶段输出
    output reg [`RegAddrBus]  wd_o,         // 目的寄存器地址（直通）
    output reg                wreg_o,       // 写使能（直通）
    output reg [`RegBus]      wdata_o       // ALU 运算结果
);

// 保存逻辑运算的结果（OR/AND/NOR/XOR）
reg [`RegBus] logicout;
// 保存移位运算的结果（SLL/SRL/SRA）
reg [`RegBus] shiftres;

// ----------------------------
// 逻辑运算单元
// ----------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        logicout <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_OR_OP:   begin
                logicout <= reg1_i | reg2_i;
            end
            `EXE_AND_OP:  begin
                logicout <= reg1_i & reg2_i;
            end
            `EXE_NOR_OP:  begin
                logicout <= ~(reg1_i | reg2_i);
            end
            `EXE_XOR_OP:  begin
                logicout <= reg1_i ^ reg2_i;
            end
            default: begin
                logicout <= `ZeroWord;
            end
        endcase
    end
end

// ----------------------------
// 移位运算单元
// 注意：移位量取自 reg1_i[4:0]（MIPS 指令中 shamt 字段为5位）
// ----------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        shiftres <= `ZeroWord;
    end else begin
        case (aluop_i)
            `EXE_SLL_OP: begin  // 逻辑左移
                shiftres <= reg2_i << reg1_i[4:0];
            end
            `EXE_SRL_OP: begin  // 逻辑右移
                shiftres <= reg2_i >> reg1_i[4:0];
            end
            `EXE_SRA_OP: begin  // 算术右移（符号扩展）
                shiftres <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]})) 
                          | (reg2_i >> reg1_i[4:0]);
            end
            default: begin
                shiftres <= `ZeroWord;
            end
        endcase
    end
end

// ----------------------------
// 根据 alusel_i 选择最终结果，并传递控制信号
// ----------------------------
always @ (*) begin
    wd_o   <= wd_i;     // 直通目的寄存器地址
    wreg_o <= wreg_i;   // 直通写使能

    case (alusel_i)
        `EXE_RES_LOGIC: begin
            wdata_o <= logicout;  // 选择逻辑运算结果
        end
        `EXE_RES_SHIFT: begin
            wdata_o <= shiftres;  // 选择移位运算结果
        end
        default: begin
            wdata_o <= `ZeroWord; // 默认输出0（安全状态）
        end
    endcase
end

endmodule