`timescale 1ns/1ps
`include "defines.v"

module openmips_min_sopc_tb_new();
    reg clk;
    reg rst;
    wire [7:0] seg;
    wire [7:0] dig;

    // 1. 实例化您修改后的顶层模块
    openmips_min_sopc dut (
        .clk(clk),
        .rst(rst),
        .seg_data_0_pin(seg),
        .seg_cs_pin(dig)
    );

    // 2. 产生 100MHz 时钟
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // 3. 产生复位信号
    initial begin
        rst = `RstEnable;   // 开始复位
        #200 rst = `RstDisable; // 200ns 后释放复位
        #2000000;           // 运行足够长的时间
        $stop;
    end

    // 4. 监控输出：当数码管信号变化时打印出来
    initial begin
        $monitor("Time: %t | Dig_En: %b | Seg_Out: %h", $time, dig, seg);
    end
endmodule
