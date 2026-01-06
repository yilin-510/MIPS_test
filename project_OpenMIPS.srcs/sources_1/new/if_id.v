//////////////////////////////////////////////////////////////////////
// Module:  if_id
// Description: IF/ID 阶段的流水线寄存器（Pipeline Register）
//              用于在取指阶段（IF）和译码阶段（ID）之间传递：
//                - 指令地址（PC）
//                - 指令内容（Instruction）
//              支持复位、冲刷（flush）和流水线暂停（stall）控制。
//////////////////////////////////////////////////////////////////////

`include "defines.v"  

// 模块声明：if_id -- 连接 IF 阶段与 ID 阶段的流水线寄存器
module if_id(
    input  wire                     clk,                          // 主时钟输入（上升沿触发寄存器更新）
    input  wire                     rst,                          // 异步复位信号（高电平有效）

    // 来自控制模块（Control Unit）的控制信号
    input  wire [5:0]               stall,                        // 流水线各级暂停信号数组
                                                              // stall[1] 控制 ID 阶段是否被暂停
                                                              // stall[2] 控制 EX 阶段是否被暂停
    input  wire                     flush,                        // 冲刷信号：当发生跳转、异常或中断时，
                                                              // 需要清空流水线中无效的后续指令

    // 来自 IF 阶段的输入数据
    input  wire [`InstAddrBus]      if_pc,                        // IF 阶段当前输出的程序计数器值（即正在取指的地址）
    input  wire [`InstBus]          if_inst,                      // IF 阶段从指令存储器读出的 32 位指令

    // 输出到 ID 阶段的数据
    output reg [`InstAddrBus]       id_pc,                        // 传递给 ID 阶段的指令地址
    output reg [`InstBus]           id_inst                       // 传递给 ID 阶段的指令内容
);

// 在每个时钟上升沿，根据控制信号决定是否更新 ID 阶段的寄存器
always @ (posedge clk) begin
    // 情况1：复位信号有效（系统初始化）
    if (rst == `RstEnable) begin
        id_pc    <= `ZeroWord;     // 将 id_pc 清零（安全初始状态）
        id_inst  <= `ZeroWord;     // 将 id_inst 清零（避免无效指令进入译码）
    end 
    // 情况2：flush 信号有效（例如发生跳转、异常、中断）
    else if (flush == 1'b1) begin
        id_pc    <= `ZeroWord;     // 清空 IF/ID 寄存器，防止无效指令继续向下传递
        id_inst  <= `ZeroWord;
    end 
    // 情况3：ID 阶段被暂停（stall[1] == `Stop），但 EX 阶段未被暂停（stall[2] == `NoStop）
    //        这种组合通常出现在"气泡插入"场景（如 load-use hazard 后插入气泡）
    else if (stall[1] == `Stop && stall[2] == `NoStop) begin
        id_pc    <= `ZeroWord;     // 插入"气泡"（bubble）：用全零指令占位
        id_inst  <= `ZeroWord;     // 确保 ID 阶段处理的是 NOP（空操作）
    end 
    // 情况4：ID 阶段未被暂停（stall[1] == `NoStop），正常传递数据
    else if (stall[1] == `NoStop) begin
        id_pc    <= if_pc;         // 将 IF 阶段的  PC 值锁存到 ID 阶段
        id_inst  <= if_inst;       // 将 IF 阶段的指令锁存到 ID 阶段
    end
    // 注意：如果 st all[1] == `Stop 且 stall[2] == `Stop（即整个流水线停住），
    //       则上述所有条件都不满足，寄存器保持原值（隐式保持，无需赋值）
end

endmodule