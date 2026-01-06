//////////////////////////////////////////////////////////////////////
// Module:  pc_reg
// Description: 指令指针寄存器PC（Program Counter Register）
//              用于在五级流水线CPU中管理程序计数器（PC）的更新逻辑，
//              支持复位、暂停（stall）、冲刷（flush）和跳转（branch）。
//////////////////////////////////////////////////////////////////////

`include "defines.v" 

// 模块声明：pc_reg
module pc_reg(
    input  wire                     clk,                          // 主时钟信号
    input  wire                     rst,                          // 异步复位信号（高电平有效）

    // 来自控制模块（Control Unit）的控制信号
    input  wire [5:0]               stall,                        // 流水线各级暂停信号（stall[0] 表示取指阶段是否暂停）
    input  wire                     flush,                        // 冲刷信号：当发生跳转或异常时，清空后续无效指令
    input  wire [`RegBus]           new_pc,                       // 当 flush 有效时，PC 被强制更新为此地址（如异常/中断入口）

    // 来自译码阶段（ID 阶段）的分支信息
    input  wire                     branch_flag_i,                // 分支跳转标志：1 表示当前指令是跳转/分支指令
    input  wire [`RegBus]           branch_target_address_i,      // 分支目标地址（由译码阶段计算得出）

    // 输出信号
    output reg [`InstAddrBus]       pc,                           // 当前程序计数器（PC）值，即下一条要取的指令地址
    output reg                      ce                            // 芯片使能信号（Chip Enable），控制 PC 是否工作
);

// 第一个 always 块：更新 PC 的值（在时钟上升沿触发）
always @ (posedge clk) begin
    // 如果芯片被禁用（ce == `ChipDisable），PC 清零（安全状态）
    if (ce == `ChipDisable) begin
        pc <= 32'h00000000;          // 将 PC 初始化为 0 地址
    end else begin
        // 正常工作状态下（ce == `ChipEnable）
        if (flush == 1'b1) begin
            // 如果 flush 信号有效（例如发生跳转、异常、中断），强制 PC 跳转到 new_pc
            pc <= new_pc;
        end else if (stall[0] == `NoStop) begin
            // 如果取指阶段没有被暂停（stall[0] 表示 IF 阶段是否 stall）
            if (branch_flag_i == `Branch) begin
                // 如果是分支指令（branch_flag_i 有效），PC 跳转到目标地址
                pc <= branch_target_address_i;
            end else begin
                // 否则，顺序执行：PC 自增 4（每条指令 4 字节）
                pc <= pc + 4'h4;     // 等价于 32'h4
            end
        end
        // 注意：如果 stall[0] != `NoStop（即取指阶段被暂停），PC 保持不变（隐式保持）
    end
end

// 第二个 always 块：控制芯片使能信号 ce（在时钟上升沿触发）
always @ (posedge clk) begin
    if (rst == `RstEnable) begin
        // 复位有效时，禁用芯片（ce = `ChipDisable）
        ce <= `ChipDisable;
    end else begin
        // 复位释放后，使能芯片（ce = `ChipEnable），允许 PC 正常工作
        ce <= `ChipEnable;
    end
end

endmodule