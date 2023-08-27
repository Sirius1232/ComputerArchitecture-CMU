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

    pc_t                pc_now;
    pc_t                pc_link, pc_link_d0, pc_link_d1, pc_link_d2;
    mips_t              instruction;
    mips_state_t        state;

    alu_ctrl_t          alu_ctrl;
    gpr_ctrl_t          gpr_ctrl;
    word_t              imm;
    word_t              in1, in2;
    word_t              hi_data, lo_data, rs_data, rt_data, rt_data_d0;
    word_t              exu_in1, exu_in2;
    word_t              exu_out1, exu_out2;
    word_t              exu_out1_d0, exu_out2_d0;
    wb_ctrl_t           wb_ctrl, wb_ctrl_d0, wb_ctrl_d1;
    word_t              wr_data1, wr_data2;

    logic               link_en, link_en_d0, link_en_d1;  // 寄存器链接

    logic   [4:0]       ram_ctrl_0;
    logic               ram_en;
    logic   [4:0]       ram_din_rt;

    raw_t               raw;
    logic               wait_exe_1, wait_exe_2, wait_exe;  // 出现数据冲突时流水线等待
    assign  wait_exe = wait_exe_1 | wait_exe_2;


    //*****************************************************
    //**                    main code
    //*****************************************************
    /*取指*/
    mips_ifu mips_ifu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .wait_exe       (wait_exe),
        .running        (running),
        .halt           (halt),
        .jmp_gpr        (),
        .pc_now         (pc_now),
        .pc_next        (pc_next),
        .pc_link        (pc_link)
    );

    assign  instruction = pc_instr;

    /*译码*/
    mips_idu mips_idu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .wait_exe       (wait_exe),
        .instruction    (instruction),
        .state          (state),
        .halt           (halt),
        .alu_ctrl       (alu_ctrl),
        .gpr_ctrl       (gpr_ctrl),
        .imm            (imm),
        .link_en        (link_en),
        .wb_ctrl        (wb_ctrl),
        .ram_ctrl       (ram_ctrl_0)
    );
    always_ff @(posedge clk) begin
        pc_link_d0 <= pc_link;
    end

    /*执行*/
    assign  hi_data = state.hi;
    assign  lo_data = state.lo;
    assign  rs_data = state.gpr[gpr_ctrl.rs];
    assign  rt_data = state.gpr[gpr_ctrl.rt];
    always_comb begin
        case (gpr_ctrl.rs_en)
            HI_EN   : in1 = hi_data;
            LO_EN   : in1 = lo_data;
            GPR_EN  : in1 = rs_data;
            IMM_EN  : in1 = imm;
        endcase
    end
    always_comb begin
        case (gpr_ctrl.rt_en)
            HI_EN   : in2 = hi_data;
            LO_EN   : in2 = lo_data;
            GPR_EN  : in2 = rt_data;
            IMM_EN  : in2 = imm;
        endcase
    end
    raw_detect raw_detect_inst(
        .gpr_ctrl       (gpr_ctrl),
        .wb_ctrl_d0     (wb_ctrl_d0),
        .wb_ctrl_d1     (wb_ctrl_d1),
        .raw            (raw)
    );
    assign  wait_exe_1 = raw.rs_mem & ram_ctrl[0];
    assign  wait_exe_2 = raw.rt_mem & ram_ctrl[0];
    always_comb begin
        if (raw.rs_mem)
            exu_in1 = (gpr_ctrl.rs_en==LO_EN) ? exu_out2 : exu_out1;
        else if (raw.rs_wbu)
            exu_in1 = (gpr_ctrl.rs_en==LO_EN) ? wr_data2 : wr_data1;
        else
            exu_in1 = in1;
    end
    always_comb begin
        if (raw.rt_mem)
            exu_in2 = (gpr_ctrl.rt_en==LO_EN) ? exu_out2 : exu_out1;
        else if (raw.rt_wbu)
            exu_in2 = (gpr_ctrl.rt_en==LO_EN) ? wr_data2 : wr_data1;
        else
            exu_in2 = in2;
    end
    mips_exu mips_exu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .wait_exe       (wait_exe),
        .alu_ctrl       (alu_ctrl),
        .exu_in1        (exu_in1),
        .exu_in2        (exu_in2),
        .exu_out1       (exu_out1),
        .exu_out2       (exu_out2)
    );
    always_ff @(posedge clk) begin
        pc_link_d1 <= pc_link_d0;
        link_en_d0 <= link_en;
        wb_ctrl_d0 <= wb_ctrl;
        ram_ctrl <= ram_ctrl_0;
        ram_din_rt <= gpr_ctrl.rt;
        rt_data_d0 <= rt_data;
    end

    /*访存*/
    assign  ram_addr = exu_out1;
    always_comb begin
        if(ram_din_rt==wb_ctrl_d1.wr_gpr && wb_ctrl_d1.wr_en && ram_din_rt!=`X0)
            ram_din = wr_data1;
        else
            ram_din = rt_data_d0;
    end
    always_ff @(posedge clk) begin
        pc_link_d2 <= pc_link_d1;
        link_en_d1 <= link_en_d0;
        wb_ctrl_d1 <= wb_ctrl_d0;
        ram_en <= ram_ctrl[0];
        exu_out1_d0 <= exu_out1;
        exu_out2_d0 <= exu_out2;
    end

    /*写回*/
    assign  wr_data1 = ram_en ? ram_dout : (link_en_d1 ? pc_link_d2 : exu_out1_d0);
    assign  wr_data2 = exu_out2_d0;
    mips_wbu mips_wbu_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .wb_ctrl        (wb_ctrl_d1),
        .wr_data1       (wr_data1),
        .wr_data2       (wr_data2),
        .state          (state)
    );



endmodule
