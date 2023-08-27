//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           ram_data.sv
// Descriptions:        数据存储器模块（访存模块）
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module ram_data (
        input                   clk,
        input           [4:0]   ram_ctrl,  // [4:2]:数据长度控制；[1]:写；[0]:使用数据存储器
        input           [31:0]  addr,
        input   word_t          wr_data,
        output  word_t          rd_data
    );


    logic   [29:0]      addr_0, addr_1, addr_2, addr_3;
    assign  addr_0 = addr[31:2] + (addr[1]|addr[0]);
    assign  addr_1 = addr[31:2] + addr[1];
    assign  addr_2 = addr[31:2] + (addr[1]&addr[0]);
    assign  addr_3 = addr[31:2];

    logic               enable;
    logic   [3:0]       wr_en, wr_en_t;
    assign  enable = ram_ctrl[0];
    always_comb begin
        case (ram_ctrl[3:1])
            3'b001  : wr_en_t = 4'b0001;
            3'b011  : wr_en_t = 4'b0011;
            3'b111  : wr_en_t = 4'b1111;
            default : wr_en_t = 4'b0000;
        endcase
    end
    always_comb begin
        case (addr[1:0])
            2'b00   : wr_en = wr_en_t;
            2'b01   : wr_en = {wr_en_t[2:0], wr_en_t[3]};
            2'b10   : wr_en = {wr_en_t[1:0], wr_en_t[3:2]};
            2'b11   : wr_en = {wr_en_t[0], wr_en_t[3:1]};
        endcase
    end

    logic   [2:0]       mask_code;
    logic   [1:0]       rd_order;
    always_ff @(posedge clk) begin
        mask_code <= ram_ctrl[4:2];
        rd_order  <= addr[1:0];
    end

    word_t              din, dout;
    logic   [7:0]       din_0, din_1, din_2, din_3;
    logic   [7:0]       dout_0, dout_1, dout_2, dout_3;
    /*写入*/
    always_comb begin
        case (ram_ctrl[3:2])
            2'b00   : din = {24'b0, wr_data[7:0]};
            2'b01   : din = {16'b0, wr_data[15:0]};
            2'b11   : din = wr_data;
            default : din = 32'd0;
        endcase
    end
    always_comb begin
        case (addr[1:0])
            2'b00   : {din_3, din_2, din_1, din_0} = din;
            2'b01   : {din_0, din_3, din_2, din_1} = din;
            2'b10   : {din_1, din_0, din_3, din_2} = din;
            2'b11   : {din_2, din_1, din_0, din_3} = din;
        endcase
    end
    /*读取*/
    always_comb begin
        case (mask_code[1:0])
            2'b00   : rd_data = {{24{~mask_code[2]&dout[7]}}, dout[7:0]};
            2'b01   : rd_data = {{16{~mask_code[2]&dout[15]}}, dout[15:0]};
            2'b11   : rd_data = dout;
            default : rd_data = 32'd0;
        endcase
    end
    always_comb begin
        case (rd_order)
            2'b00   : dout = {dout_3, dout_2, dout_1, dout_0};
            2'b01   : dout = {dout_0, dout_3, dout_2, dout_1};
            2'b10   : dout = {dout_1, dout_0, dout_3, dout_2};
            2'b11   : dout = {dout_2, dout_1, dout_0, dout_3};
        endcase
    end

    dram_8bit dram_8bit_inst_0 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[0]),
        .addra      (addr_0),
        .dina       (din_0),
        .douta      (dout_0)
    );
    dram_8bit dram_8bit_inst_1 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[1]),
        .addra      (addr_1),
        .dina       (din_1),
        .douta      (dout_1)
    );
    dram_8bit dram_8bit_inst_2 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[2]),
        .addra      (addr_2),
        .dina       (din_2),
        .douta      (dout_2)
    );
    dram_8bit dram_8bit_inst_3 (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en[3]),
        .addra      (addr_3),
        .dina       (din_3),
        .douta      (dout_3)
    );


endmodule
