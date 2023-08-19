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
        input   mips_t          instruction,
        input   mips_state_t    state,
        output  logic           halt,
        /*控制信号*/
        output  alu_ctrl_t      alu_ctrl,
        output  word_t          alu_in1,
        output  word_t          alu_in2,
        output  word_t          data,   // 复用数据，用于跳转指令需要的寄存器/立即数值，以及访存中的待写入数据
        /*分支跳转控制*/
        output  logic   [3:0]   jmp_ctrl, // 指令跳转功能控制（[3]:拼接or相加，[2]:使用寄存器，[1]:无条件跳转，[0]:条件分支）
        output  logic           link_en,  // 寄存器链接
        /*访存控制*/
        output  logic   [4:0]   ram_ctrl,  // [4:2]:数据长度控制；[1]:写；[0]:使用数据存储器
        /*写寄存器*/
        output  logic           wr_en,
        output  logic   [4:0]   wr_gpr
    );

    logic   [5:0]       op;
    logic   [4:0]       rs;
    logic   [4:0]       rt;
    logic   [4:0]       rd;
    logic   [4:0]       shamt;
    logic   [5:0]       funct;
    logic   [25:0]      target;
    word_t              imm_i;
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
    assign  imm_i = {16'd0, instruction[15:0]};
    assign  imm_i_sext = {{16{instruction[15]}}, instruction[15:0]};

    assign  halt = (instruction==`SYSCALL) ? 1'b1 : 1'b0;

    always_comb begin
        case (op)
            `SPECIAL    : begin
                case (funct)
                    `OP0_ADD, `OP0_ADDU : alu_ctrl = ALU_ADD;
                    `OP0_AND    : alu_ctrl = ALU_AND;
                    `OP0_JR, `OP0_JALR  : alu_ctrl = ALU_NOP;
                    `OP0_NOR    : alu_ctrl = ALU_NOR;
                    `OP0_OR     : alu_ctrl = ALU_OR;
                    `OP0_SLL, `OP0_SLLV : alu_ctrl = ALU_SLL;
                    `OP0_SRL, `OP0_SRLV : alu_ctrl = ALU_SRL;
                    `OP0_SRA, `OP0_SRAV : alu_ctrl = ALU_SRA;
                    `OP0_SUB, `OP0_SUBU : alu_ctrl = ALU_SUB;
                    `OP0_SLT    : alu_ctrl = ALU_LT;
                    `OP0_SLTU   : alu_ctrl = ALU_LTU;
                    `OP0_XOR    : alu_ctrl = ALU_XOR;
                    default     : alu_ctrl = ALU_NOP;
                endcase
            end
            `REGIMM     : begin
                case (rt)
                    `OP1_BLTZ, `OP1_BLTZAL  : alu_ctrl = ALU_LT;
                    `OP1_BGEZ, `OP1_BGEZAL  : alu_ctrl = ALU_GE;
                    default     : alu_ctrl = ALU_NOP;
                endcase
            end
            `OP_ADDI, `OP_ADDIU : alu_ctrl = ALU_ADD;
            `OP_ANDI    : alu_ctrl = ALU_AND;
            `OP_BEQ     : alu_ctrl = ALU_EQ;
            `OP_BNE     : alu_ctrl = ALU_NE;
            `OP_BGTZ    : alu_ctrl = ALU_GT;
            `OP_BLEZ    : alu_ctrl = ALU_LE;
            `OP_J, `OP_JAL  : alu_ctrl = ALU_NOP;
            `OP_ORI     : alu_ctrl = ALU_OR;
            `OP_SLTI    : alu_ctrl = ALU_LT;
            `OP_SLTIU   : alu_ctrl = ALU_LTU;
            `OP_XORI    : alu_ctrl = ALU_XOR;
            `OP_LUI     : alu_ctrl = ALU_SLL;
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU : alu_ctrl = ALU_ADD;
            `OP_SB, `OP_SH, `OP_SW  : alu_ctrl = ALU_ADD;
            default     : alu_ctrl = ALU_NOP;
        endcase
    end

    always_comb begin
        case (op)
            `SPECIAL    : begin
                case (funct)
                    `OP0_ADD, `OP0_ADDU, `OP0_AND, `OP0_NOR, `OP0_OR, `OP0_XOR, 
                    `OP0_SLT, `OP0_SLTU, `OP0_SUB, `OP0_SUBU : begin
                        alu_in1 = state.gpr[rs];
                        alu_in2 = state.gpr[rt];
                    end
                    `OP0_SLL, `OP0_SRA, `OP0_SRL : begin
                        alu_in1 = shamt;
                        alu_in2 = state.gpr[rt];
                    end
                    `OP0_SLLV, `OP0_SRAV, `OP0_SRLV : begin
                        alu_in1 = state.gpr[rs];
                        alu_in2 = state.gpr[rt];
                    end
                    default : begin
                        alu_in1 = 32'd0;
                        alu_in2 = 32'd0;
                    end
                endcase
            end
            `REGIMM     : begin
                case (rt)
                    `OP1_BLTZ, `OP1_BGEZ, `OP1_BLTZAL, `OP1_BGEZAL : begin
                        alu_in1 = state.gpr[rs];
                        alu_in2 = 32'd0;
                    end
                    default : begin
                        alu_in1 = 32'd0;
                        alu_in2 = 32'd0;
                    end
                endcase
            end
            `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU, 
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU, 
            `OP_SB, `OP_SH, `OP_SW : begin
                alu_in1 = state.gpr[rs];
                alu_in2 = imm_i_sext;
            end
            `OP_ANDI, `OP_ORI, `OP_XORI : begin
                alu_in1 = state.gpr[rs];
                alu_in2 = imm_i;
            end
            `OP_BEQ, `OP_BNE : begin
                alu_in1 = state.gpr[rs];
                alu_in2 = state.gpr[rt];
            end
            `OP_BGTZ, `OP_BLEZ : begin
                alu_in1 = state.gpr[rs];
                alu_in2 = 32'd0;
            end
            `OP_LUI : begin
                alu_in1 = 16;
                alu_in2 = imm_i;
            end
            default : begin
                alu_in1 = 32'd0;
                alu_in2 = 32'd0;
            end
        endcase
    end

    always_comb begin
        case (op)
            `SPECIAL    : begin
                if(funct != `OP0_JR) begin
                    wr_en = 1'b1;
                    wr_gpr = rd;
                end
                else begin
                    wr_en = 1'b0;
                    wr_gpr = `X0;
                end
            end
            `REGIMM     : begin
                case (rt)
                    `OP1_BLTZAL, `OP1_BGEZAL : begin
                        wr_en = 1'b1;
                        wr_gpr = `X31;
                    end
                    default : begin
                        wr_en = 1'b0;
                        wr_gpr = `X0;
                    end
                endcase
            end
            `OP_ADDI, `OP_ADDIU, `OP_SLTI, `OP_SLTIU, 
            `OP_ANDI, `OP_ORI, `OP_XORI, `OP_LUI, 
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU: begin
                wr_en = 1'b1;
                wr_gpr = rt;
            end
            `OP_JAL : begin
                wr_en = 1'b1;
                wr_gpr = `X31;
            end
            default : begin
                wr_en = 1'b0;
                wr_gpr = `X0;
            end
        endcase
    end

    always_comb begin
        case (op)
            `SPECIAL    : begin
                case (funct)
                    `OP0_JR : begin
                        jmp_ctrl = 4'b0110;
                        link_en = 1'b0;
                    end
                    `OP0_JALR : begin
                        jmp_ctrl = 4'b0110;
                        link_en = 1'b1;
                    end
                    default : begin
                        jmp_ctrl = 4'b0000;
                        link_en = 1'b0;
                    end
                endcase
            end
            `REGIMM     : begin
                case (rt)
                    `OP1_BLTZ, `OP1_BGEZ : begin
                        jmp_ctrl = 4'b0001;
                        link_en = 1'b0;
                    end
                    `OP1_BLTZAL, `OP1_BGEZAL : begin
                        jmp_ctrl = 4'b0001;
                        link_en = 1'b1;
                    end
                    default : begin
                        jmp_ctrl = 4'b0000;
                        link_en = 1'b0;
                    end
                endcase
            end
            `OP_BEQ, `OP_BNE, `OP_BGTZ, `OP_BLEZ : begin
                jmp_ctrl = 4'b0001;
                link_en = 1'b0;
            end
            `OP_J   : begin
                jmp_ctrl = 4'b1010;
                link_en = 1'b0;
            end
            `OP_JAL : begin
                jmp_ctrl = 4'b1010;
                link_en = 1'b1;
            end
            default : begin
                jmp_ctrl = 4'b0000;
                link_en = 1'b0;
            end
        endcase
    end

    always_comb begin
        case (op)
            `OP_LB, `OP_LH, `OP_LW, `OP_LBU, `OP_LHU : ram_ctrl = {op[2:0], 2'b01};
            `OP_SB, `OP_SH, `OP_SW  : ram_ctrl = {op[2:0], 2'b11};
            default : ram_ctrl = 5'b00000;
        endcase
    end

    always_comb begin
        case (op)
            `SPECIAL    : begin
                case (funct)
                    `OP0_JR, `OP0_JALR : data = state.gpr[rs];
                    default : data = 32'd0;
                endcase
            end
            `REGIMM     : begin
                case (rt)
                    `OP1_BLTZ, `OP1_BGEZ, `OP1_BLTZAL, `OP1_BGEZAL : data = {imm_i_sext[29:0], 2'b00};
                    default : data = 32'd0;
                endcase
            end
            `OP_BEQ, `OP_BNE, `OP_BGTZ, `OP_BLEZ : data = {imm_i_sext[29:0], 2'b00};
            `OP_J, `OP_JAL : data = target;
            `OP_SB, `OP_SH, `OP_SW  : data = state.gpr[rt];
            default : data = 32'd0;
        endcase
    end


endmodule
