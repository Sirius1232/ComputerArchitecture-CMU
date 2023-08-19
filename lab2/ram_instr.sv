//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           ram_instr.sv
// Descriptions:        指令存储器模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module ram_instr (
        input                   clk,
        input           [31:0]  addr,
        input                   wr_en,
        input   word_t          wr_data,
        input                   rd_en,
        output  word_t          rd_data
    );

    wire                enable;
    assign  enable = wr_en ^ rd_en;

    iram iram_inst (
        .clka       (clk),
        .ena        (enable),
        .wea        (wr_en),  // ram 读写使能信号,高电平写入,低电平读出
        .addra      (addr[21:2]),
        .dina       (wr_data),
        .douta      (rd_data)
    );


endmodule
