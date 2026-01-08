module seg_driver(
    input wire clk,           // 100MHz 主时钟
    input wire rst,           // 低电平有效复位（针对你说的始终为1的情况）
    input wire [31:0] data_in, 
    output reg [7:0] seg_o,   
    output reg [7:0] dig_en_o  
);

    // 1. 分频计数器
    reg [18:0] cnt;
    always @(posedge clk or negedge rst) begin // 改为下降沿异步复位
        if (!rst) begin                       // 低电平复位
            cnt <= 19'd0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end

    // 2. 边缘检测产生使能信号
    reg cnt_v_r; 
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            cnt_v_r <= 1'b0;
        end else begin
            cnt_v_r <= cnt[18];
        end
    end
    
    // 只有在 cnt[20] 上升沿时产生一个周期的脉冲
    wire scan_en = (cnt[18] == 1'b1 && cnt_v_r == 1'b0);

    // 3. 扫描计数器 (0-7)
    reg [2:0] scan_cnt;
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            scan_cnt <= 3'd0;
        end else if (scan_en) begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

    // 4. 位选和数值选择 (组合逻辑)
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
            default: begin dig_en_o = 8'h00; hex_val = 4'h0;          end
        endcase
    end

    // 5. 段选译码 (组合逻辑)
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