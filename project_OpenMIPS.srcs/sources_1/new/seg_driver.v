// Module: seg_driver
// Description: 适配 EG1 开发板的 8 位共阴极数码管驱动
// 硬件特性：位选高电平有效，段选高电平点亮

module seg_driver(
    input wire clk,           // 100MHz
    input wire rst,           // 高电平复位
    input wire [31:0] data_in, // CPU 传入的 32 位数据
    output reg [7:0] seg_o,    // 段选
    output reg [7:0] dig_en_o  // 位选 (8 位)
);

    // 分频产生扫描时钟 (约 1kHz)
    reg [16:0] cnt;
    always @(posedge clk or posedge rst) begin
        if (rst) cnt <= 0;
        else cnt <= cnt + 1;
    end
    wire scan_clk = cnt[16];

    // 扫描计数器 (0-7)
    reg [2:0] scan_cnt;
    always @(posedge scan_clk or posedge rst) begin
        if (rst) scan_cnt <= 0;
        else scan_cnt <= scan_cnt + 1;
    end

    // 获取当前位要显示的 4 位 16 进制数
    reg [3:0] hex_val;
    always @(*) begin
        case(scan_cnt)
            3'b000: begin dig_en_o = 8'h01; hex_val = data_in[3:0];   end
            3'b001: begin dig_en_o = 8'h02; hex_val = data_in[7:4];   end
            3'b010: begin dig_en_o = 8'h04; hex_val = data_in[11:8];  end
            3'b011: begin dig_en_o = 8'h08; hex_val = data_in[15:12]; end
            3'b100: begin dig_en_o = 8'h10; hex_val = data_in[19:16]; end
            3'b101: begin dig_en_o = 8'h20; hex_val = data_in[23:20]; end
            3'b110: begin dig_en_o = 8'h40; hex_val = data_in[27:24]; end
            3'b111: begin dig_en_o = 8'h80; hex_val = data_in[31:28]; end
        endcase
    end

    // 16 进制到 7 段码 (高电平点亮)
    always @(*) begin
        case(hex_val)
            4'h0: seg_o = 8'h3f; 4'h1: seg_o = 8'h06; 4'h2: seg_o = 8'h5b; 4'h3: seg_o = 8'h4f;
            4'h4: seg_o = 8'h66; 4'h5: seg_o = 8'h6d; 4'h6: seg_o = 8'h7d; 4'h7: seg_o = 8'h07;
            4'h8: seg_o = 8'h7f; 4'h9: seg_o = 8'h6f; 4'ha: seg_o = 8'h77; 4'hb: seg_o = 8'h7c;
            4'hc: seg_o = 8'h39; 4'hd: seg_o = 8'h5e; 4'he: seg_o = 8'h79; 4'hf: seg_o = 8'h71;
            default: seg_o = 8'h00;
        endcase
    end
endmodule
