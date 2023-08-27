//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           mips_idu.sv
// Descriptions:        译码模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module mips_idu (
        input                   clk,
        input                   rst_n,
        input                   wait_exe,
        input   mips_t          instruction,
        input   mips_state_t    state,
        output  logic           halt,
        /*控制信号*/
        output  alu_ctrl_t      alu_ctrl,
        output  gpr_ctrl_t      gpr_ctrl,
        output  word_t          imm,
        /*分支跳转控制*/
        output  logic           link_en,  // 寄存器链接
        /*访存控制*/
        output  logic   [4:0]   ram_ctrl,  // [4:2]:数据长度控制；[1]:写；[0]:使用数据存储器
        /*写寄存器*/
        output  wb_ctrl_t       wb_ctrl
    );

    logic   [5:0]       op;
    logic   [4:0]       rs;
    logic   [4:0]       rt;
    logic   [4:0]       rd;
    logic   [4:0]       shamt;
    logic   [5:0]       funct;
    logic   [25:0]      target;
    logic   [15:0]      imm_i;
    word_t              imm_i_sext;


    //*****************************************************
    //**                    main code
    //*****************************************************
    assign  op = instruction[31:26];
    assign  rs = instruction[25:21];
    assign  rt = instruction[20:16];
    assign  rd = instruction[15:11];
    assign  shamt = instruction[10:6];
    assign  funct = instruction[5:0];
    assign  target = instruction[25:0];
    assign  imm_i = instruction[15:0];
    assign  imm_i_sext = {{16{instruction[15]}}, instruction[15:0]};

    assign  halt = (instruction==`SYSCALL) ? 1'b1 : 1'b0;

    /*ALU控制*/
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            alu_ctrl <= ALU_NOP;
        else if(wait_exe)
            alu_ctrl <= alu_ctrl;
        else begin
            case (op)
                `SPECIAL    : begin
                    case (funct)
                        `OP0_ADD, `OP0_ADDU : alu_ctrl <= ALU_ADD;
                        `OP0_AND    : alu_ctrl <= ALU_AND;
                        `OP0_JR, `OP0_JALR  : alu_ctrl <= ALU_NOP;
                        `OP0_NOR    : alu_ctrl <= ALU_NOR;
                        `OP0_OR     : alu_ctrl <= ALU_OR;
                        `OP0_SLL, `OP0_SLLV : alu_ctrl <= ALU_SLL;
                        `OP0_SRL, `OP0_SRLV : alu_ctrl <= ALU_SRL;
                        `OP0_SRA, `OP0_SRAV : alu_ctrl <= ALU_SRA;
                        `OP0_SUB, `OP0_SUBU : alu_ctrl <= ALU_SUB;
                        `OP0_SLT    : alu_ctrl <= ALU_LT;
                        `OP0_SLTU   : alu_ctrl <= ALU_LTU;
                        `OP0_XOR    : alu_ctrl <= ALU_XOR;
                        `OP0_MFHI, `OP0_MFLO: alu_ctrl <= ALU_ADD;
                        `OP0_MTHI, `OP0_MTLO: alu_ctrl <= ALU_ADD;
                        `OP0_MULT   : alu_ctrl <= ALU_MULT;
                        `OP0_MULTU  : alu_ctrl <= ALU_MULTU;
                        `OP0_DIV    : alu_ctrl <= ALU_DIV;
                        `OP0_DIVU   : alu_ctrl <= ALU_DIVU;
                        default     : alu_ctrl <= ALU_NOP;
                    endcase
                end
                `REGIMM     : begin
                    case (rt)
                        `OP1_BLTZ, `OP1_BLTZAL  : alu_ctrl <= ALU_LT;
                        `OP1_BGEZ, `OP1_BGEZAL  : alu_ctrl <= ALU_GE;
                        default     : alu_ctrl <= ALU_NOP;
                    endcase
                end
                `OP_ADDI, `OP_ADDIU : alu_ctrl <= ALU_ADD;
                `OP_ANDI    : alu_ctrl <= ALU_AND;
                `OP_BEQ     : alu_ctrl <= ALU_EQ;
                `OP_BNE     : alu_ctrl <= ALU_NE;
                `OP_BGTZ    : alu_ctrl <= ALU_GT;
                `OP_BLEZ    : alu_ctrl <= ALU_LE;
                `OP_J, `OP_JAL  : alu_ctrl <= ALU_NOP;
                `OP_ORI     : alu_ctrl <= ALU_OR;
                `OP_SLTI    : alu_ctrl <= ALU_LT;
                `OP_SLTIU   : alu_ctrl <= ALU_LTU;
                `OP_XORI    : alu_ctrl <= ALU_XOR;
                `OP_LUI     : alu_ctrl <= ALU_ADD;
                `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU : alu_ctrl <= ALU_ADD;
                `OP_SB, `OP_SH, `OP_SW  : alu_ctrl <= ALU_ADD;
                default     : alu_ctrl <= ALU_NOP;
            endcase
        end
    end

    /*ALU输入数据*/
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            gpr_ctrl.rs_en <= IMM_EN;
            gpr_ctrl.rs <= `X0;
            gpr_ctrl.rt_en <= IMM_EN;
            gpr_ctrl.rt <= `X0;
        end
        else if(wait_exe)
            gpr_ctrl <= gpr_ctrl;
        else begin
            case (op)
                `SPECIAL    : begin
                    case (funct)
                        `OP0_ADD, `OP0_ADDU, `OP0_AND, `OP0_NOR, `OP0_OR, `OP0_XOR, 
                        `OP0_SLT, `OP0_SLTU, `OP0_SUB, `OP0_SUBU,
                        `OP0_SLLV, `OP0_SRAV, `OP0_SRLV,
                        `OP0_MULT, `OP0_MULTU, `OP0_DIV, `OP0_DIVU: begin
                            gpr_ctrl.rs_en <= GPR_EN;
                            gpr_ctrl.rs <= rs;
                            gpr_ctrl.rt_en <= GPR_EN;
                            gpr_ctrl.rt <= rt;
                        end
                        `OP0_SLL, `OP0_SRA, `OP0_SRL : begin
                            gpr_ctrl.rs_en <= IMM_EN;
                            gpr_ctrl.rs <= `X0;
                            gpr_ctrl.rt_en <= GPR_EN;
                            gpr_ctrl.rt <= rt;
                        end
                        `OP0_MFHI   : begin
                            gpr_ctrl.rs_en <= HI_EN;
                            gpr_ctrl.rs <= `X0;
                            gpr_ctrl.rt_en <= GPR_EN;
                            gpr_ctrl.rt <= `X0;
                        end
                        `OP0_MFLO   : begin
                            gpr_ctrl.rs_en <= LO_EN;
                            gpr_ctrl.rs <= `X0;
                            gpr_ctrl.rt_en <= GPR_EN;
                            gpr_ctrl.rt <= `X0;
                        end
                        `OP0_MTHI, `OP0_MTLO    : begin
                            gpr_ctrl.rs_en <= GPR_EN;
                            gpr_ctrl.rs <= rs;
                            gpr_ctrl.rt_en <= GPR_EN;
                            gpr_ctrl.rt <= `X0;
                        end
                        default : begin
                            gpr_ctrl.rs_en <= IMM_EN;
                            gpr_ctrl.rs <= `X0;
                            gpr_ctrl.rt_en <= IMM_EN;
                            gpr_ctrl.rt <= `X0;
                        end
                    endcase
                end
                `REGIMM     : begin
                    case (rt)
                        `OP1_BLTZ, `OP1_BGEZ, `OP1_BLTZAL, `OP1_BGEZAL : begin
                            gpr_ctrl.rs_en <= GPR_EN;
                            gpr_ctrl.rs <= rs;
                            gpr_ctrl.rt_en <= GPR_EN;
                            gpr_ctrl.rt <= `X0;
                        end
                        default : begin
                            gpr_ctrl.rs_en <= IMM_EN;
                            gpr_ctrl.rs <= `X0;
                            gpr_ctrl.rt_en <= IMM_EN;
                            gpr_ctrl.rt <= `X0;
                        end
                    endcase
                end
                `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU, 
                `OP_ANDI, `OP_ORI, `OP_XORI, 
                `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU: begin
                    gpr_ctrl.rs_en <= GPR_EN;
                    gpr_ctrl.rs <= rs;
                    gpr_ctrl.rt_en <= IMM_EN;
                    gpr_ctrl.rt <= `X0;
                end
                `OP_SB, `OP_SH, `OP_SW : begin
                    gpr_ctrl.rs_en <= GPR_EN;
                    gpr_ctrl.rs <= rs;
                    gpr_ctrl.rt_en <= IMM_EN;
                    gpr_ctrl.rt <= rt;
                end
                `OP_BEQ, `OP_BNE : begin
                    gpr_ctrl.rs_en <= GPR_EN;
                    gpr_ctrl.rs <= rs;
                    gpr_ctrl.rt_en <= GPR_EN;
                    gpr_ctrl.rt <= rt;
                end
                `OP_BGTZ, `OP_BLEZ : begin
                    gpr_ctrl.rs_en <= GPR_EN;
                    gpr_ctrl.rs <= rs;
                    gpr_ctrl.rt_en <= GPR_EN;
                    gpr_ctrl.rt <= `X0;
                end
                `OP_LUI : begin
                    gpr_ctrl.rs_en <= GPR_EN;
                    gpr_ctrl.rs <= `X0;
                    gpr_ctrl.rt_en <= IMM_EN;
                    gpr_ctrl.rt <= `X0;
                end
                default : begin
                    gpr_ctrl.rs_en <= IMM_EN;
                    gpr_ctrl.rs <= `X0;
                    gpr_ctrl.rt_en <= IMM_EN;
                    gpr_ctrl.rt <= `X0;
                end
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            imm <= 32'd0;
        end
        else if(wait_exe) begin
            imm <= imm;
        end
        else begin
            case (op)
                `SPECIAL    : begin
                    case (funct)
                        `OP0_SLL, `OP0_SRA, `OP0_SRL : imm <= shamt;
                        default : imm <= 32'd0;
                    endcase
                end
                `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU, 
                `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU, 
                `OP_SB, `OP_SH, `OP_SW : begin
                    imm <= imm_i_sext;
                end
                `OP_ANDI, `OP_ORI, `OP_XORI : imm <= imm_i;
                `OP_LUI : imm <= {imm_i, 16'b0};
                default : imm <= 32'd0;
            endcase
        end
    end

    /*写寄存器控制*/
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wb_ctrl.wr_en <= 1'b0;
            wb_ctrl.wr_gpr <= `X0;
            wb_ctrl.wr_hi <= 1'b0;
            wb_ctrl.wr_lo <= 1'b0;
        end
        else if(wait_exe)
            wb_ctrl <= wb_ctrl;
        else begin
            case (op)
                `SPECIAL    : begin
                    case (funct)
                        `OP0_JR : begin
                            wb_ctrl.wr_en <= 1'b0;
                            wb_ctrl.wr_gpr <= `X0;
                        end
                        `OP0_MTHI, `OP0_MTLO, `OP0_MULT, `OP0_MULTU, `OP0_DIV, `OP0_DIVU : begin
                            wb_ctrl.wr_en <= 1'b1;
                            wb_ctrl.wr_gpr <= `X0;
                        end
                        default : begin
                            wb_ctrl.wr_en <= 1'b1;
                            wb_ctrl.wr_gpr <= rd;
                        end
                    endcase
                end
                `REGIMM     : begin
                    case (rt)
                        `OP1_BLTZAL, `OP1_BGEZAL : begin
                            wb_ctrl.wr_en <= 1'b1;
                            wb_ctrl.wr_gpr <= `X31;
                        end
                        default : begin
                            wb_ctrl.wr_en <= 1'b0;
                            wb_ctrl.wr_gpr <= `X0;
                        end
                    endcase
                end
                `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU, 
                `OP_ANDI, `OP_ORI, `OP_XORI, `OP_LUI, 
                `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU: begin
                    wb_ctrl.wr_en <= 1'b1;
                    wb_ctrl.wr_gpr <= rt;
                end
                `OP_JAL : begin
                    wb_ctrl.wr_en <= 1'b1;
                    wb_ctrl.wr_gpr <= `X31;
                end
                default : begin
                    wb_ctrl.wr_en <= 1'b0;
                    wb_ctrl.wr_gpr <= `X0;
                end
            endcase
            case (op)
                `SPECIAL    : begin
                    case (funct)
                        `OP0_MTHI   : begin
                            wb_ctrl.wr_hi <= 1'b1;
                            wb_ctrl.wr_lo <= 1'b0;
                        end
                        `OP0_MTLO   : begin
                            wb_ctrl.wr_hi <= 1'b0;
                            wb_ctrl.wr_lo <= 1'b1;
                        end
                        `OP0_MULT, `OP0_MULTU, `OP0_DIV, `OP0_DIVU  : begin
                            wb_ctrl.wr_hi <= 1'b1;
                            wb_ctrl.wr_lo <= 1'b1;
                        end
                        default : begin
                            wb_ctrl.wr_hi <= 1'b0;
                            wb_ctrl.wr_lo <= 1'b0;
                        end
                    endcase
                end
                default : begin
                    wb_ctrl.wr_hi <= 1'b0;
                    wb_ctrl.wr_lo <= 1'b0;
                end
            endcase
        end
    end


    /*分支跳转控制*/
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            link_en <= 1'b0;
        else if(wait_exe)
            link_en <= link_en;
        else begin
            if(op==`SPECIAL && funct==`OP0_JALR)
                link_en <= 1'b1;
            else if(op==`REGIMM && rt inside {`OP1_BLTZAL, `OP1_BGEZAL})
                link_en <= 1'b1;
            else if(op==`OP_JAL)
                link_en <= 1'b1;
            else
                link_en <= 1'b0;
        end
    end

    /*数据存储器控制*/
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            ram_ctrl <= 5'b00000;
        else if(wait_exe)
            ram_ctrl <= ram_ctrl;
        else begin
            case (op)
                `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU : ram_ctrl <= {op[2:0], 2'b01};
                `OP_SB, `OP_SH, `OP_SW  : ram_ctrl <= {op[2:0], 2'b11};
                default : ram_ctrl <= 5'b00000;
            endcase
        end
    end


endmodule
