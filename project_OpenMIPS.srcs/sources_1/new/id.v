// Description: ID模块：对指令进行译码，得到最终运算的类型，子类型，源操作数1
//源操作数2，要写入的目的寄存器地址等信息
//其中运算类型指的是：逻辑运算，移位运算，算术运算等
//子类型指：更详细的运算类型

`include "defines.v"

module id (
    input  wire           clk,
    input  wire           rst,

    // 来自译码阶段的信号
    input  wire [`InstAddrBus] pc_i,
    input  wire [`InstBus]   inst_i,

    // 读取 regfile 的值
    input  wire [`RegBus]   reg1_data_i,
    input  wire [`RegBus]   reg2_data_i,

    // 输出到 regfile 的信息
    output reg            reg1_read_o,
    output reg            reg2_read_o,
    output reg [`RegAddrBus] reg1_addr_o,
    output reg [`RegAddrBus] reg2_addr_o,

    // 送到执行阶段的信息
    output reg [`AluOpBus] aluop_o,
    output reg [`AluSelBus] alusel_o,
    output reg [`RegBus]   reg1_o,
    output reg [`RegBus]   reg2_o,
    output reg [`RegAddrBus] wd_o,
    output reg             wreg_o
);

// 取指令的指令码，功能码
wire[5:0] op = inst_i[31:26];     // 指令的 opcode（第26-31位）

// 保存指令执行需要的立即数
reg [`RegBus] imm;

// 指示指令是否有效
reg instValid;

// 第一段：对指令进行译码
always @(*) begin
    if (rst == `RstEnable) begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= `NOPRegAddr;
        wreg_o <= `WriteDisable;
        instValid <= `InstInvalid;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        reg1_addr_o <= `NOPRegAddr;
        reg2_addr_o <= `NOPRegAddr;
        imm <= 32'h0;
    end else begin
        aluop_o <= `EXE_NOP_OP;
        alusel_o <= `EXE_RES_NOP;
        wd_o <= inst_i[15:11];    //【R_type:rd】 目标寄存器在指令中的位置
        wreg_o <= `WriteDisable;
        instValid <= `InstInvalid;
        reg1_read_o <= 1'b0;
        reg2_read_o <= 1'b0;
        reg1_addr_o <= inst_i[25:21];  //【I/R_type：rs】默认通过Regfile读端口1读取寄存器地址
        reg2_addr_o <= inst_i[20:16]; //【I/R_type:rt】默认通过Regfile读端口2读取的寄存器地址
        imm <= `ZeroWord;
        case (op)
            `EXE_ORI: begin  //依据op判断是否是ori指令
                // ori 指令需要将结果写入目的寄存器，所以 wreg_o 为 WriteEnable
                wreg_o <= `WriteEnable;

                // 运算子类型是逻辑"或"运算
                aluop_o <= `EXE_OR_OP;
                //运算类型是逻辑运算
                alusel_o <= `EXE_RES_LOGIC;

                // 需要通过 Regfile 读端口 1 读取源寄存器
                reg1_read_o <= 1'b1;
                // 不需要通过 Regfile 读端口 2 读取源寄存器
                reg2_read_o <= 1'b0;  

                // 指令执行需要的立即数
                imm <= {16'h0, inst_i[15:0]};  // 扩展为 32 位

                // 指令执行要写的目的寄存器地址
                wd_o <= inst_i[20:16];

                // ori 指令是有效指令
                instValid <= `InstValid;
            end
            default: begin
            end
        endcase
    end
end

// 第二段：确定进行运算的源操作数 1
always @(*) begin
    if (rst == `RstEnable) begin
        reg1_o <= `ZeroWord;
    end else if (reg1_read_o == 1'b1) begin
        reg1_o <= reg1_data_i;  // 从 Regfile 读端口 1 获取数据
    end else if (reg1_read_o == 1'b0) begin
        reg1_o <= imm;          // 如果不需要读寄存器，则使用立即数
    end else begin
        reg1_o <= `ZeroWord;
    end
end

// 第三段：确定进行运算的源操作数 2
always @(*) begin
    if (rst == `RstEnable) begin
        reg2_o <= `ZeroWord;
    end else if (reg2_read_o == 1'b1) begin
        reg2_o <= reg2_data_i;  // 从 Regfile 读端口 2 获取数据
    end else if (reg2_read_o == 1'b0) begin
        reg2_o <= imm;          // 使用立即数
    end else begin
        reg2_o <= `ZeroWord;
    end
end

endmodule