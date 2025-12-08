// Description: EX模块：从ID/EX模块得到运算类型alusel_i,运算子类型aluop_i,
// 源操作数reg1_i,源操作数reg2_i,要写的目的寄存器地址wd_i,并依据这些数据进行运算

`include "defines.v"

module ex (
    input  wire           rst,

    // 译码阶段送到执行阶段的信息
    input  wire [`AluOpBus]   aluop_i,      // ALU 子操作类型（如 OR、SLL、MFHI 等）
    input  wire [`AluSelBus]  alusel_i,     // ALU 主类型选择（逻辑 / 移位 / 移动）
    input  wire [`RegBus]     reg1_i,       // 源操作数1（可能为 rs、shamt 或立即数）
    input  wire [`RegBus]     reg2_i,       // 源操作数2（通常为 rt 或立即数）
    input  wire [`RegAddrBus] wd_i,         // 目标寄存器地址（rd 或 rt）
    input  wire               wreg_i,       // 是否需要写回通用寄存器

    // 当前 HI/LO 寄存器值（来自 HILO_REG）
    input  wire [`RegBus]     hi_i,
    input  wire [`RegBus]     lo_i,

    // 回写阶段（WB）对 HI/LO 的写回信息（用于前递）
    input  wire [`RegBus]     wb_hi_i,
    input  wire [`RegBus]     wb_lo_i,
    input  wire               wb_whilo_i,   // WB 阶段是否写 HI/LO

    // 访存阶段（MEM）对 HI/LO 的写回信息（用于前递，优先级高于 WB）
    input  wire [`RegBus]     mem_hi_i,
    input  wire [`RegBus]     mem_lo_i,
    input  wire               mem_whilo_i,  // MEM 阶段是否写 HI/LO

    // 执行阶段输出（送至 MEM/WB 阶段）
    output reg  [`RegAddrBus] wd_o,         // 目标寄存器地址（直通）
    output reg                wreg_o,       // 写使能（直通）
    output reg  [`RegBus]     wdata_o,      // ALU 运算结果

    // HI/LO 写回输出（用于更新 HILO_REG）
    output reg  [`RegBus]     hi_o,
    output reg  [`RegBus]     lo_o,
    output reg                whilo_o       // 是否在本周期写 HI/LO
);

// 各功能单元的中间结果
reg [`RegBus] logicout;     // 逻辑运算结果（OR/AND/XOR/NOR）
reg [`RegBus] shiftres;     // 移位运算结果（SLL/SRL/SRA）
reg [`RegBus] moveres;      // 移动类指令结果（MFHI/MFLO/MOVZ/MOVN）
reg [`RegBus] HI;           // 当前有效的 HI 值（考虑前递）
reg [`RegBus] LO;           // 当前有效的 LO 值（考虑前递）

// ----------------------------
// 逻辑运算单元：处理 AND/OR/XOR/NOR
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
// 移位运算单元：SLL/SRL/SRA
// 注意：移位量取自 reg1_i[4:0]（5 位 shamt）
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
// 获取当前有效的 HI/LO 值（解决数据相关）
// 优先级：MEM 阶段写 > WB 阶段写 > 当前 HI/LO 寄存器值
// ----------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        {HI, LO} <= {`ZeroWord, `ZeroWord};
    end else if (mem_whilo_i == `WriteEnable) begin
        {HI, LO} <= {mem_hi_i, mem_lo_i};
    end else if (wb_whilo_i == `WriteEnable) begin
        {HI, LO} <= {wb_hi_i, wb_lo_i};
    end else begin
        {HI, LO} <= {hi_i, lo_i};
    end
end

// ----------------------------
// 移动类指令处理：MFHI / MFLO / MOVZ / MOVN
// 注意：MOVZ/MOVN 的实际条件判断在 ID 或 EX 控制逻辑中完成，
//       此处仅传递 reg1_i 作为候选结果（由上游控制 wreg_o）
// ----------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        moveres <= `ZeroWord;
    end else begin
        moveres <= `ZeroWord;
        case (aluop_i)
            `EXE_MFHI_OP: begin
                moveres <= HI;
            end
            `EXE_MFLO_OP: begin
                moveres <= LO;
            end
            `EXE_MOVZ_OP: begin
                moveres <= reg1_i;
            end
            `EXE_MOVN_OP: begin
                moveres <= reg1_i;
            end
            default: begin
                // 保持默认值
            end
        endcase
    end
end

// ----------------------------
// 根据 alusel_i 选择最终 ALU 输出，并直通控制信号
// ----------------------------
always @ (*) begin
    wd_o   <= wd_i;
    wreg_o <= wreg_i;
    case (alusel_i)
        `EXE_RES_LOGIC: begin
            wdata_o <= logicout;
        end
        `EXE_RES_SHIFT: begin
            wdata_o <= shiftres;
        end
        `EXE_RES_MOVE: begin
            wdata_o <= moveres;
        end
        default: begin
            wdata_o <= `ZeroWord;
        end
    endcase
end

// ----------------------------
// 处理 MTHI / MTLO 指令：生成 HI/LO 写回信号和数据
// ----------------------------
always @ (*) begin
    if (rst == `RstEnable) begin
        whilo_o <= `WriteDisable;
        hi_o    <= `ZeroWord;
        lo_o    <= `ZeroWord;
    end else if (aluop_i == `EXE_MTHI_OP) begin
        whilo_o <= `WriteEnable;
        hi_o    <= reg1_i;    // 将 reg1_i 写入 HI
        lo_o    <= LO;        // LO 保持不变
    end else if (aluop_i == `EXE_MTLO_OP) begin
        whilo_o <= `WriteEnable;
        hi_o    <= HI;        // HI 保持不变
        lo_o    <= reg1_i;    // 将 reg1_i 写入 LO
    end else begin
        whilo_o <= `WriteDisable;
        hi_o    <= `ZeroWord;
        lo_o    <= `ZeroWord;
    end
end

endmodule