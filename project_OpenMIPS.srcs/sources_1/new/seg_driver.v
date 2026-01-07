// Module: seg_driver
// Description: 驱动 EG01 开发板上的 4 位共阳极数码管，显示 32 位数据的低 16 位（以 16 进制形式）
// 也可以根据需要修改为显示 10 进制。

module seg_driver(
    input wire clk,          // 100MHz 系统时钟
    input wire rst,          // 复位信号
    input wire [31:0] data_in, // CPU 传入的 32 位数据
    output reg [7:0] seg_o,   // 段选 {dp, g, f, e, d, c, b, a}
    output reg [3:0] dig_en_o // 位选 (4 位数码管)
);

    // 分频产生扫描时钟 (约 1kHz 用于数码管刷新)
    reg [16:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) cnt <= 0;
        else cnt <= cnt + 1;
    end
    wire scan_clk = cnt[16]; // 扫描时钟

    // 扫描计数器，用于切换显示的位数
    reg [1:0] scan_cnt;
    always @(posedge scan_clk or posedge rst) begin
        if (rst) scan_cnt <= 0;
        else scan_cnt <= scan_cnt + 1;
    end

    // 获取当前位要显示的 4 位 16 进制数
    reg [3:0] hex_val;
    always @(*) begin
        case(scan_cnt)
            2'b00: begin dig_en_o = 4'b1110; hex_val = data_in[3:0];   end // 第一位
            2'b01: begin dig_en_o = 4'b1101; hex_val = data_in[7:4];   end // 第二位
            2'b10: begin dig_en_o = 4'b1011; hex_val = data_in[11:8];  end // 第三位
            2'b11: begin dig_en_o = 4'b0111; hex_val = data_in[15:12]; end // 第四位
        endcase
    end

// 16 进制到 7 段码的转换 (共阴极：1 点亮，0 熄灭)
    always @(*) begin
    case(hex_val)
        4'h0: seg_o = 8'h3f; // 0011_1111 (a,b,c,d,e,f 亮)
        4'h1: seg_o = 8'h06; // 0000_0110 (b,c 亮)
        4'h2: seg_o = 8'h5b; // 0101_1011
        4'h3: seg_o = 8'h4f; // 0100_1111
        4'h4: seg_o = 8'h66; // 0110_0110
        4'h5: seg_o = 8'h6d; // 0110_1101
        4'h6: seg_o = 8'h7d; // 0111_1101
        4'h7: seg_o = 8'h07; // 0000_0111
        4'h8: seg_o = 8'h7f; // 0111_1111
        4'h9: seg_o = 8'h6f; // 0110_1111
        4'ha: seg_o = 8'h77;
        4'hb: seg_o = 8'h7c;
        4'hc: seg_o = 8'h39;
        4'hd: seg_o = 8'h5e;
        4'he: seg_o = 8'h79;
        4'hf: seg_o = 8'h71;
        default: seg_o = 8'h00; // 全灭
    endcase
end

endmodule
