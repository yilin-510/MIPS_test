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
`define EXE_ORI            6'b001101  // 指令 ori 的指令码
`define EXE_NOP            6'b000000  // 指令 nop 的指令码

/***************** 与ALU计算相关的控制码 ******************/
`define EXE_OR_OP          8'b0010101  // OR 操作的控制码
`define EXE_NOP_OP         8'b0000000  // NOP 操作的控制码

/******************* ALU选择相关 ****************************/
`define EXE_RES_LOGIC      3'b001   // 执行逻辑运算时的 ALU 选择
`define EXE_RES_NOP        3'b000   // NOP 操作时的 ALU 选择

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
