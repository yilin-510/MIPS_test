//////////////////////////////////////////////////////////////////////
// Module:  inst_rom
// File:    inst_rom.v
// Description: 指令存储器 - 修正路径与地址对齐版本
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module inst_rom(
    input wire                    ce,    // 芯片使能信号
    input wire[`InstAddrBus]      addr,  // 来自 CPU 的字节地址 (0, 4, 8...)
    output reg[`InstBus]          inst   // 输出的 32 位指令
);

    // 定义存储阵列
    (* ram_style = "block" *) reg[`InstBus] inst_mem[0:`InstMemNum-1];

    // 初始化 ROM 数据
    initial begin
        // 1. 首先尝试使用工程相对路径（推荐，需将 data 文件加入 Vivado Sources）
        // 2. 如果相对路径失败，再使用修正后的正斜杠绝对路径
        $readmemh("E:\\Vivado_test\\project_OpenMIPS\\project_OpenMIPS.srcs\\sources_1\\new\\inst_rom.data", inst_mem);
        
        // 如果您坚持使用绝对路径，请务必使用正斜杠 / 如下：
        // $readmemh("E:/Vivado_test/project_OpenMIPS/project_OpenMIPS.srcs/sources_1/new/inst_rom.data", inst_mem);
    end

    // 组合逻辑读取指令
    always @ (*) begin
        if (ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            // 关键点：MIPS 地址是按字节计数的，但数组索引是按字计数的
            // addr[13:2] 相当于 addr / 4，去掉了低两位的字节偏移
            inst <= inst_mem[addr[12:2]];
        end
    end

endmodule
