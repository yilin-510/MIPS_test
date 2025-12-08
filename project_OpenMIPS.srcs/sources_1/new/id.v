// Description: ID模块：对指令进行译码，得到最终运算的类型，子类型，源操作数1
// 源操作数2，要写入的目的寄存器地址等信息
// 其中运算类型指的是：逻辑运算，移位运算，算术运算等
// 子类型指：更详细的运算类型

`include "defines.v"

module id (
    input  wire           clk,
    input  wire           rst,

    // 来自取指阶段的信号
    input  wire [`InstAddrBus] pc_i,
    input  wire [`InstBus]     inst_i,

    // 从寄存器堆读出的数据
    input  wire [`RegBus]      reg1_data_i,   // rs 的值
    input  wire [`RegBus]      reg2_data_i,   // rt 的值

    // 执行阶段（EX）回传的写回信息（用于前递）
    input wire                 ex_wreg_i,      // EX 阶段是否要写寄存器
    input wire [`RegBus]       ex_wdata_i,     // EX 阶段写入的数据
    input wire [`RegAddrBus]   ex_wd_i,        // EX 阶段写入的寄存器地址

    // 访存阶段（MEM）回传的写回信息（用于前递）
    input wire                 mem_wreg_i,     // MEM 阶段是否要写寄存器
    input wire [`RegBus]       mem_wdata_i,    // MEM 阶段写入的数据
    input wire [`RegAddrBus]   mem_wd_i,       // MEM 阶段写入的寄存器地址

    // 输出到寄存器堆的读使能与地址
    output reg                 reg1_read_o,    // 是否通过端口1读 rs
    output reg                 reg2_read_o,    // 是否通过端口2读 rt
    output reg [`RegAddrBus]   reg1_addr_o,    // rs 地址（端口1）
    output reg [`RegAddrBus]   reg2_addr_o,    // rt 地址（端口2）

    // 输出到执行阶段（EX）的信息
    output reg [`AluOpBus]     aluop_o,        // ALU 子操作类型（如 OR、SLL 等）
    output reg [`AluSelBus]    alusel_o,       // ALU 主类型选择（逻辑 / 移位）
    output reg [`RegBus]       reg1_o,         // 源操作数1（可能来自 regfile 或 imm）
    output reg [`RegBus]       reg2_o,         // 源操作数2（可能来自 regfile 或 imm）
    output reg [`RegAddrBus]   wd_o,           // 目标寄存器地址（rd 或 rt）
    output reg                 wreg_o          // 是否需要写回
);

// 指令字段提取
wire [5:0] op  = inst_i[31:26];   // opcode（主操作码）
wire [4:0] op2 = inst_i[10:6];    // shamt（移位量，也用于某些特殊指令判断）
wire [5:0] op3 = inst_i[5:0];     // funct（R-type 功能码）
wire [5:0] op4 = inst_i[20:16];   // rt 字段（有时用于辅助判断）

// 立即数（用于 I-type 指令）
reg [`RegBus] imm;

// 指令有效性标志
reg instValid;

// ============================================================================
// 第一段：指令译码（根据 opcode 和 funct 确定操作类型、操作数来源、写回信息等）
// ============================================================================
always @(*) begin
    if (rst == `RstEnable) begin
        aluop_o      <= `EXE_NOP_OP;
        alusel_o     <= `EXE_RES_NOP;
        wd_o         <= `NOPRegAddr;
        wreg_o       <= `WriteDisable;
        instValid    <= `InstInvalid;
        reg1_read_o  <= 1'b0;
        reg2_read_o  <= 1'b0;
        reg1_addr_o  <= `NOPRegAddr;
        reg2_addr_o  <= `NOPRegAddr;
        imm          <= 32'h0;
    end else begin
        // 默认设置（适用于大多数 R/I 型指令）
        aluop_o      <= `EXE_NOP_OP;
        alusel_o     <= `EXE_RES_NOP;
        wd_o         <= inst_i[15:11];        // R-type: rd
        wreg_o       <= `WriteDisable;
        instValid    <= `InstInvalid;
        reg1_read_o  <= 1'b0;
        reg2_read_o  <= 1'b0;
        reg1_addr_o  <= inst_i[25:21];        // rs
        reg2_addr_o  <= inst_i[20:16];        // rt
        imm          <= `ZeroWord;

        case (op)
            `EXE_SPECIAL_INST: begin  // R-type 指令（opcode = 6'b000000）
                case (op2)
                    5'b00000: begin  // 标准 R-type（shamt=0，如 add, sub, or 等）
                        case (op3)
                            `EXE_OR: begin
                                aluop_o     <= `EXE_OR_OP;
                                alusel_o    <= `EXE_RES_LOGIC;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;
                                reg2_read_o <= 1'b1;
                                instValid   <= `InstValid;
                            end
                            `EXE_AND: begin
                                aluop_o     <= `EXE_AND_OP;
                                alusel_o    <= `EXE_RES_LOGIC;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;
                                reg2_read_o <= 1'b1;
                                instValid   <= `InstValid;
                            end
                            `EXE_XOR: begin
                                aluop_o     <= `EXE_XOR_OP;
                                alusel_o    <= `EXE_RES_LOGIC;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;
                                reg2_read_o <= 1'b1;
                                instValid   <= `InstValid;
                            end
                            `EXE_NOR: begin
                                aluop_o     <= `EXE_NOR_OP;
                                alusel_o    <= `EXE_RES_LOGIC;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;
                                reg2_read_o <= 1'b1;
                                instValid   <= `InstValid;
                            end
                            `EXE_SLLV: begin
                                aluop_o     <= `EXE_SLL_OP;
                                alusel_o    <= `EXE_RES_SHIFT;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;  // rs 作为移位量
                                reg2_read_o <= 1'b1;  // rt 作为被移位数
                                instValid   <= `InstValid;
                            end
                            `EXE_SRLV: begin
                                aluop_o     <= `EXE_SRL_OP;
                                alusel_o    <= `EXE_RES_SHIFT;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;
                                reg2_read_o <= 1'b1;
                                instValid   <= `InstValid;
                            end
                            `EXE_SRAV: begin
                                aluop_o     <= `EXE_SRA_OP;
                                alusel_o    <= `EXE_RES_SHIFT;
                                wreg_o      <= `WriteEnable;
                                reg1_read_o <= 1'b1;
                                reg2_read_o <= 1'b1;
                                instValid   <= `InstValid;
                            end
                            `EXE_SYNC: begin
                                aluop_o     <= `EXE_NOP_OP;
                                alusel_o    <= `EXE_RES_NOP;
                                wreg_o      <= `WriteDisable;
                                reg1_read_o <= 1'b0;
                                reg2_read_o <= 1'b1;  // 可能保留读取（但无用）
                                instValid   <= `InstValid;
                            end
                            `EXE_MFHI: begin
								wreg_o <= `WriteEnable;		
								aluop_o <= `EXE_MFHI_OP;
		  						alusel_o <= `EXE_RES_MOVE;   
		  						reg1_read_o <= 1'b0;	
		  						reg2_read_o <= 1'b0;
		  						instValid <= `InstValid;	
								end
							`EXE_MFLO: begin
								wreg_o <= `WriteEnable;		
								aluop_o <= `EXE_MFLO_OP;
		  						alusel_o <= `EXE_RES_MOVE;   
		  						reg1_read_o <= 1'b0;	
		  						reg2_read_o <= 1'b0;
		  						instValid <= `InstValid;	
								end
							`EXE_MTHI: begin
								wreg_o <= `WriteDisable;		
								aluop_o <= `EXE_MTHI_OP;
		  						reg1_read_o <= 1'b1;	
		  						reg2_read_o <= 1'b0; 
		  						instValid <= `InstValid;	
								end
							`EXE_MTLO: begin
								wreg_o <= `WriteDisable;	
								aluop_o <= `EXE_MTLO_OP;
		  						reg1_read_o <= 1'b1;	
		  						reg2_read_o <= 1'b0; 
		  						instValid <= `InstValid;	
								end
							`EXE_MOVN: begin
								aluop_o <= `EXE_MOVN_OP;
		  						alusel_o <= `EXE_RES_MOVE;   
		  						reg1_read_o <= 1'b1;	
		  						reg2_read_o <= 1'b1;
		  						instValid <= `InstValid;
								 	if(reg2_o != `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end
								end
							`EXE_MOVZ: begin
								aluop_o <= `EXE_MOVZ_OP;
		  						alusel_o <= `EXE_RES_MOVE;   
		  						reg1_read_o <= 1'b1;	
		  						reg2_read_o <= 1'b1;
		  						instValid <= `InstValid;
								 	if(reg2_o == `ZeroWord) begin
	 									wreg_o <= `WriteEnable;
	 								end else begin
	 									wreg_o <= `WriteDisable;
	 								end		  							
								end	
                            default: begin
                                // 未支持的 funct，保持默认 NOP
                            end
                        endcase
                    end
                    default: begin
                        // 非标准 shamt，暂不处理
                    end
                endcase
            end

            // I-type 指令
            `EXE_ORI: begin
                wreg_o        <= `WriteEnable;
                aluop_o       <= `EXE_OR_OP;
                alusel_o      <= `EXE_RES_LOGIC;
                reg1_read_o   <= 1'b1;        // rs 需要读
                reg2_read_o   <= 1'b0;        // rt 不读，用立即数
                instValid     <= `InstValid;
                imm           <= {16'h0, inst_i[15:0]};  // 无符号扩展
                wd_o          <= inst_i[20:16];          // 写回 rt
            end
            `EXE_ANDI: begin
                alusel_o      <= `EXE_RES_LOGIC;
                aluop_o       <= `EXE_AND_OP;
                wreg_o        <= `WriteEnable;
                reg1_read_o   <= 1'b1;
                reg2_read_o   <= 1'b0;
                imm           <= {16'h0, inst_i[15:0]};
                wd_o          <= inst_i[20:16];
                instValid     <= `InstValid;
            end
            `EXE_XORI: begin
                alusel_o      <= `EXE_RES_LOGIC;
                aluop_o       <= `EXE_XOR_OP;
                wreg_o        <= `WriteEnable;
                reg1_read_o   <= 1'b1;
                reg2_read_o   <= 1'b0;
                imm           <= {16'h0, inst_i[15:0]};
                wd_o          <= inst_i[20:16];
                instValid     <= `InstValid;
            end
            `EXE_LUI: begin
                alusel_o      <= `EXE_RES_LOGIC;
                aluop_o       <= `EXE_OR_OP;   // 用 OR 实现：0 | imm << 16
                wreg_o        <= `WriteEnable;
                reg1_read_o   <= 1'b1;         // 实际上 rs 未使用，但保持读使能（可优化）
                reg2_read_o   <= 1'b0;
                imm           <= {inst_i[15:0], 16'h0};  // 高16位为立即数，低16位为0
                wd_o          <= inst_i[20:16];
                instValid     <= `InstValid;
            end
            `EXE_PREF: begin
                alusel_o      <= `EXE_RES_NOP;
                aluop_o       <= `EXE_NOP_OP;
                wreg_o        <= `WriteDisable;
                reg1_read_o   <= 1'b0;
                reg2_read_o   <= 1'b0;
                instValid     <= `InstValid;
            end
            default: begin
                // 未支持的 opcode，保持默认 NOP
            end
        endcase

        // 单独处理 SLL/SRL/SRA（shamt 在 [10:6]，rs=0）
        if (inst_i[31:21] == 11'b00000000000) begin
            if (op3 == `EXE_SLL) begin
                wreg_o        <= `WriteEnable;
                aluop_o       <= `EXE_SLL_OP;
                alusel_o      <= `EXE_RES_SHIFT;
                reg1_read_o   <= 1'b0;        // rs=0，不读寄存器
                reg2_read_o   <= 1'b1;        // rt 作为被移位数
                imm[4:0]      <= inst_i[10:6]; // shamt 作为立即数（移位量）
                wd_o          <= inst_i[15:11];
                instValid     <= `InstValid;
            end else if (op3 == `EXE_SRL) begin
                wreg_o        <= `WriteEnable;
                aluop_o       <= `EXE_SRL_OP;
                alusel_o      <= `EXE_RES_SHIFT;
                reg1_read_o   <= 1'b0;
                reg2_read_o   <= 1'b1;
                imm[4:0]      <= inst_i[10:6];
                wd_o          <= inst_i[15:11];
                instValid     <= `InstValid;
            end else if (op3 == `EXE_SRA) begin
                wreg_o        <= `WriteEnable;
                aluop_o       <= `EXE_SRA_OP;
                alusel_o      <= `EXE_RES_SHIFT;
                reg1_read_o   <= 1'b0;
                reg2_read_o   <= 1'b1;
                imm[4:0]      <= inst_i[10:6];
                wd_o          <= inst_i[15:11];
                instValid     <= `InstValid;
            end
        end
    end
end

// ============================================================================
// 第二段：确定源操作数1（reg1_o）
// 优先级：EX 前递 > MEM 前递 > 寄存器堆 > 立即数
// ============================================================================
always @(*) begin
    if (rst == `RstEnable) begin
        reg1_o <= `ZeroWord;
    end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
        reg1_o <= ex_wdata_i;    // EX 阶段前递
    end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
        reg1_o <= mem_wdata_i;   // MEM 阶段前递
    end else if (reg1_read_o == 1'b1) begin
        reg1_o <= reg1_data_i;   // 从寄存器堆读取
    end else if (reg1_read_o == 1'b0) begin
        reg1_o <= imm;           // 使用立即数（如 I-type 或 SLL）
    end else begin
        reg1_o <= `ZeroWord;
    end
end

// ============================================================================
// 第三段：确定源操作数2（reg2_o）
// 优先级：EX 前递 > MEM 前递 > 寄存器堆 > 立即数
// ============================================================================
always @(*) begin
    if (rst == `RstEnable) begin
        reg2_o <= `ZeroWord;
    end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
        reg2_o <= ex_wdata_i;    // EX 阶段前递
    end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
        reg2_o <= mem_wdata_i;   // MEM 阶段前递
    end else if (reg2_read_o == 1'b1) begin
        reg2_o <= reg2_data_i;   // 从寄存器堆读取
    end else if (reg2_read_o == 1'b0) begin
        reg2_o <= imm;           // 使用立即数
    end else begin
        reg2_o <= `ZeroWord;
    end
end

endmodule