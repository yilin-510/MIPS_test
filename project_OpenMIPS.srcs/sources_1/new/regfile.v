//Description: Regfiles模块：实现32个32位通用整数寄存器，
//可以同时进行两个寄存器的读操作和一个寄存器的写操作

`include "defines.v"

module regfile (
    input  wire           clk,
    input  wire           rst,

    // 写端口
    input  wire           we,           // 写使能
    input  wire [`RegAddrBus] waddr,   // 写地址
    input  wire [`RegBus]   wdata,     // 写数据

    // 读端口 1
    input  wire           re1,          // 读使能 1
    input  wire [`RegAddrBus] raddr1,  // 读地址 1
    output reg [`RegBus]  rdata1,      // 读数据 1

    // 读端口 2
    input  wire           re2,          // 读使能 2
    input  wire [`RegAddrBus] raddr2,  // 读地址 2
    output reg [`RegBus]  rdata2       // 读数据 2
);

// 第一段：定义 32 个 32 位寄存器
reg [`RegBus] regs[0:`RegNum-1];

// 第二段：写操作
always @(posedge clk) begin
    if (rst == `RstDisable) begin
        if (we == `WriteEnable && waddr != `RegNumLog2'h0) begin
            regs[waddr] <= wdata;
        end
    end
end

// 第三段：读端口 1 的读操作
always @(*) begin
    if (rst == `RstEnable) begin
        rdata1 <= `ZeroWord;
    end else if (raddr1 == `RegNumLog2'h0) begin
        rdata1 <= `ZeroWord;
    end else if (raddr1 == waddr && we == `WriteEnable && re1 == `ReadEnable) begin
        rdata1 <= wdata;  // 读写冲突时，优先返回写入的数据（Forwarding）
    end else if (re1 == `ReadEnable) begin
        rdata1 <= regs[raddr1];
    end else begin
        rdata1 <= `ZeroWord;
    end
end

// 第四段：读端口 2 的读操作
always @(*) begin
    if (rst == `RstEnable) begin
        rdata2 <= `ZeroWord;
    end else if (raddr2 == `RegNumLog2'h0) begin
        rdata2 <= `ZeroWord;
    end else if (raddr2 == waddr && we == `WriteEnable && re2 == `ReadEnable) begin
        rdata2 <= wdata;  // 同样支持读写冲突时的前向（Forwarding）
    end else if (re2 == `ReadEnable) begin
        rdata2 <= regs[raddr2];
    end else begin
        rdata2 <= `ZeroWord;
    end
end

endmodule