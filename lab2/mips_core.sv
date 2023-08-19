//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           mips_core.sv
// Descriptions:        cpu核心模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module mips_core (
        input                   clk,
        input                   rst_n,
        input                   running,
        output  pc_t            pc_next,
        input   mips_t          pc_instr,
        output  logic   [4:0]   ram_ctrl,  // [4:2]:数据长度控制；[1]:写；[0]:使用数据存储器
        output  logic   [31:0]  ram_addr,
        input   word_t          ram_dout,
        output  word_t          ram_din,
        output  logic           halt
    );

    pc_t                pc_now, pc_link;
    mips_t              instruction;
    mips_state_t        state;

    alu_ctrl_t          alu_ctrl;
    word_t              exu_in1, exu_in2, exu_out;
    logic               wr_en;
    logic   [4:0]       wr_gpr;
    word_t              wr_data;

    logic   [3:0]       jmp_ctrl; // 指令跳转功能控制（[3]:拼接or相加，[2]:使用寄存器，[1]:无条件跳转，[0]:条件分支）
    logic   [2:0]       jmp_flag;
    word_t              data;
    logic               link_en;  // 寄存器链接


    //*****************************************************
    //**                    main code
    //*****************************************************
    /*取指*/
    mips_ifu mips_ifu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .running        (running),
        .halt           (halt),
        .jmp_flag       (jmp_flag),
        .jmp_data       (data),
        .pc_now         (pc_now),
        .pc_next        (pc_next),
        .pc_link        (pc_link)
    );
    assign  jmp_flag[2] = jmp_ctrl[3];
    assign  jmp_flag[1] = jmp_ctrl[2];
    assign  jmp_flag[0] = jmp_ctrl[1] | jmp_ctrl[0] & exu_out[0];

    assign  instruction = pc_instr;

    mips_idu mips_idu_inst(
        .instruction    (instruction),
        .state          (state),
        .halt           (halt),
        .alu_ctrl       (alu_ctrl),
        .alu_in1        (exu_in1),
        .alu_in2        (exu_in2),
        .jmp_ctrl       (jmp_ctrl),
        .data           (data),
        .link_en        (link_en),
        .wr_en          (wr_en),
        .wr_gpr         (wr_gpr),
        .ram_ctrl       (ram_ctrl)
    );

    mips_exu mips_exu_inst(
        .alu_ctrl       (alu_ctrl),
        .exu_in1        (exu_in1),
        .exu_in2        (exu_in2),
        .exu_out        (exu_out)
    );

    assign  ram_addr = exu_out;
    assign  ram_din = data;
    assign  wr_data = ram_ctrl[0] ? ram_dout : (link_en ? pc_link : exu_out);

    mips_wbu mips_wbu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .wr_en          (wr_en),
        .wr_gpr         (wr_gpr),
        .wr_data        (wr_data),
        .state          (state)
    );



endmodule
