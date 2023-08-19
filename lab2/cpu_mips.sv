//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           cpu_mips.sv
// Descriptions:        CPU顶层模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module cpu_mips (
        input                   clk,
        input                   rst_n,
        input                   start_flag,  // 系统开始工作
        input           [31:0]  n,
        output  pc_t            lc,  // 下载程序计数器
        input   mips_t          instr_load
    );

    pc_t                pc;
    mips_t              instruction;
    logic               halt;

    logic   [3:0]       status;
    //SM State Define
    localparam  IDLE = 4'd0;
    localparam  LOAD = 4'd1;
    localparam  RUN = 4'd2;
    
    /*State Machine*/
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            status <= IDLE;
        end
        else begin
            case (status)
                IDLE : status <= start_flag ? LOAD : IDLE;
                LOAD : status <= (lc[31:2] == n-1) ? RUN : LOAD;
                RUN  : status <= (halt) ? IDLE : RUN;
                default : status <= IDLE;
            endcase
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            lc <= 32'd0;
        end
        else begin
            case (status)
                IDLE : lc <= 32'd0;
                LOAD : lc <= lc + 32'd4;
                RUN  : lc <= 32'd0;
                default : lc <= 32'd0;
            endcase
        end
    end

    logic               loading, running;
    assign  loading = (status==LOAD) ? 1'b1 : 1'b0;
    assign  running = (status==RUN ) ? 1'b1 : 1'b0;

    logic   [31:0]      addr_i;
    assign  addr_i = {32{loading}}&lc | {32{running}}&pc;

    logic   [4:0]       ram_ctrl;
    word_t              ram_dout, ram_din;
    logic   [31:0]      addr_d;

    mips_core mips_core_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .pc_next        (pc),
        .pc_instr       (instruction),
        .ram_ctrl       (ram_ctrl),
        .ram_addr       (addr_d),
        .ram_dout       (ram_dout),
        .ram_din        (ram_din),
        .halt           (halt)
    );

    ram_instr ram_instr_inst(
        .clk            (clk),
        .addr           (addr_i),
        .wr_en          (loading),
        .wr_data        (instr_load),
        .rd_en          (running),
        .rd_data        (instruction)
    );

    ram_data ram_data_inst(
        .clk            (~clk),
        .ram_ctrl       (ram_ctrl),
        .addr           (addr_d),
        .wr_data        (ram_din),
        .rd_data        (ram_dout)
    );


endmodule
