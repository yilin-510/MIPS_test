`ifndef DEFINES_V
`define DEFINES_V

/**************** 全局的宏定义   *******************/
`define RstEnable          1'b1    // 复位信号有效
`define RstDisable         1'b0    // 复位信号无效
`define ZeroWord           32'h00000000  // 32 位的数值 0
`define WriteEnable        1'b1    // 使能写
`define WriteDisable       1'b0    // 禁止写
`define ReadEnable         1'b1    // 使能读
`define ReadDisable        1'b0    // 禁止读
`define AluOpBus           7:0     // 译码阶段的输出 aluop_o 的宽度
`define AluSelBus          2:0     // 译码阶段的输出 alusel_o 的宽度
`define InstValid          1'b0    // 指令有效
`define InstInvalid        1'b1    // 指令无效
`define True_v             1'b1    // 逻辑"真"
`define False_v            1'b0    // 逻辑"假"
`define ChipEnable         1'b1    // 芯片使能
`define ChipDisable        1'b0    // 芯片禁止

/***************** 与具体指令有关的宏定义 ***************/

// 逻辑运算类指令的功能码（Function Code）【R型指令的功能码0~5】
`define EXE_AND   6'b100100    // and 指令的功能码
`define EXE_OR    6'b100101    // or 指令的功能码
`define EXE_XOR   6'b100110    // xor 指令的功能码
`define EXE_NOR   6'b100111    // nor 指令的功能码

// 立即数逻辑运算类指令的指令码（Opcode）【I型指令的指令码26~31】
`define EXE_ANDI  6'b001100    // andi 指令的指令码
`define EXE_ORI   6'b001101    // ori 指令的指令码
`define EXE_XORI  6'b001110    // xori 指令的指令码
`define EXE_LUI   6'b001111    // lui 指令的指令码

// 移位操作指令的功能码【R型指令的功能码0~5】
`define EXE_SLL   6'b000000    // sll 指令的功能码
`define EXE_SLLV  6'b000100    // sllv 指令的功能码
`define EXE_SRL   6'b000010    // sra 指令的功能码
`define EXE_SRLV  6'b000110    // srlv 指令的功能码
`define EXE_SRA   6'b000011    // sra 指令的功能码
`define EXE_SRAV  6'b000111    // srav 指令的功能码

//移动类指令的功能码【R型指令的功能码0~5】
`define EXE_MOVZ  6'b001010    // movz 指令的功能码
`define EXE_MOVN  6'b001011    // movn 指令的功能码
`define EXE_MFHI  6'b010000    // mfhi 指令的功能码
`define EXE_MTHI  6'b010001    // mthi 指令的功能码
`define EXE_MFLO  6'b010010    // mflo 指令的功能码
`define EXE_MTLO  6'b010011    // mtlo 指令的功能码

// 特殊控制指令【R型指令的功能码0~5】
`define EXE_SYNC  6'b011111    // sync 指令的功能码
`define EXE_PREF  6'b100011    // pref 指令的功能码

// SPECIAL 类指令的指令码【R型指令的指令码26~31】
`define EXE_SPECIAL_INST 6'b000000  // SPECIAL 类指令的指令码

/***************** 与ALU计算相关的控制码【自行拟定所得】 ******************/
//AluOp（运算子类型）
`define EXE_NOP_OP		8'b00000000
`define EXE_AND_OP   	8'b00100100
`define EXE_OR_OP    	8'b00100101
`define EXE_XOR_OP  	8'b00100110
`define EXE_NOR_OP  	8'b00100111
`define EXE_LUI_OP  	8'b01011100 

// 移位运算子类型码，6种移位指令共用
`define EXE_SLL_OP  	8'b01111100 
`define EXE_SRL_OP  	8'b00000010
`define EXE_SRA_OP		8'b00000011

//移位操作指令类型码
`define EXE_MOVZ_OP  8'b00001010
`define EXE_MOVN_OP  8'b00001011
`define EXE_MFHI_OP  8'b00010000
`define EXE_MTHI_OP  8'b00010001
`define EXE_MFLO_OP  8'b00010010
`define EXE_MTLO_OP  8'b00010011

/******************* ALU选择相关【自行拟定所得】 ****************************/
`define EXE_RES_LOGIC      3'b001   // 执行逻辑运算时的 ALU 选择
`define EXE_RES_NOP        3'b000   // NOP 操作时的 ALU 选择
`define EXE_RES_SHIFT 	3'b010			// 移位运算
`define EXE_RES_MOVE 3'b011	

//**************与指令存储器 ROM 有关的宏定义 ******************/
`define InstAddrBus        31:0     // ROM 的地址总线宽度
`define InstBus            31:0     // ROM 的数据总线宽度

/****************** ROM实际大小相关宏定义 *************************/
`define InstMemNum         131071   // ROM 的实际大小为 128KB (2^17 = 131072, 减去一个地址)
`define InstMemNumLog2     17       // ROM 实际使用的地址线宽度（log2(128K) = 17）

/************* 与通用寄存器 Regfile 有关的宏定义 *********************/
`define RegAddrBus         4:0      // Regfile 模块的地址线宽度（5 位，支持 32 个寄存器）
`define RegBus             31:0     // Regfile 模块的数据线宽度（32 位）
`define RegWidth           32       // 通用寄存器的宽度（32 位）
`define DoubleRegWidth     64       // 两倍的通用寄存器的数据宽度（用于乘法或双精度）
`define DoubleRegBus       63:0     // 两倍的通用寄存器的数据线宽度
`define RegNum             32       // 通用寄存器的数量
`define RegNumLog2         5        // 寻址通用寄存器使用的地址位数（log2(32) = 5）
`define NOPRegAddr         5'b00000 // NOP 指令对应的寄存器地址（通常为 $0）

`endif // DEFINES_V