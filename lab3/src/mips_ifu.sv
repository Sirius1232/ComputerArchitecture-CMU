//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           mips_ifu.sv
// Descriptions:        取指模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module mips_ifu (
        input                   clk,
        input                   rst_n,
        input                   wait_exe,
        input                   running,  // 程序运行标志
        input                   halt,
        input   word_t          jmp_gpr,
        output  pc_t            pc_now,  // 程序计数器
        output  pc_t            pc_next,
        output  pc_t            pc_link
    );

    logic               running_d;
    logic               pc_move;
    pc_t                pc_seq, pc_jump;

    word_t              jmp_imm;
    logic   [2:0]       jmp_flag;  // [2]:拼接or相加，[1]:使用寄存器；[0]:跳转标志
    assign  jmp_flag = 3'b000;

    //*****************************************************
    //**                    main code
    //*****************************************************
    assign  pc_jump = jmp_flag[1] ? jmp_gpr : (jmp_flag[2] ? {pc_now[31:28], jmp_imm[25:0], 2'b00} : pc_now + jmp_imm);
    assign  pc_seq = pc_now + 32'd4;
    assign  pc_link = pc_seq;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            running_d <= 1'b0;
        else
            running_d <= running;
    end
    assign  pc_move = running_d & ~halt;

    always_comb begin
        if(pc_move) begin
            if(wait_exe)
                pc_next = pc_now;
            else if(jmp_flag[0])
                pc_next = pc_jump;
            else
                pc_next = pc_seq;
        end
        else
            pc_next = pc_now;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            pc_now <= `PC_START;
        else if(wait_exe)
            pc_now <= pc_now;
        else
            pc_now <= pc_next;
    end


endmodule
