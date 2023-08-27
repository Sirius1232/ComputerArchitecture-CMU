//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           mips_exu.sv
// Descriptions:        执行模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module mips_exu (
        input                   clk,
        input                   rst_n,
        input                   wait_exe,
        input   alu_ctrl_t      alu_ctrl,
        input   word_t          exu_in1,
        input   word_t          exu_in2,
        output  word_t          exu_out1,
        output  word_t          exu_out2
    );

    logic signed [31:0] tmp1, tmp2;
    assign  tmp1 = exu_in1;
    assign  tmp2 = exu_in2;

    logic   [63:0]      alu_out;
    logic   [63:0]      mult, multu, div, divu;
    assign  mult = tmp1 * tmp2;
    assign  multu = exu_in1 * exu_in2;
    assign  div[31: 0] = tmp1 / tmp2;
    assign  div[63:32] = tmp1 % tmp2;
    assign  divu[31: 0] = exu_in1 / exu_in2;
    assign  divu[63:32] = exu_in1 % exu_in2;


    //*****************************************************
    //**                    main code
    //*****************************************************
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            exu_out1 <= 32'd0;
            exu_out2 <= 32'd0;
        end
        else if(wait_exe) begin
            exu_out1 <= 32'd0;
            exu_out2 <= 32'd0;
        end
        else begin
            case (alu_ctrl)
                ALU_MULT, ALU_MULTU, ALU_DIV, ALU_DIVU  : exu_out1 <= alu_out[63:32];
                default: exu_out1 <= alu_out[31:0];
            endcase
            exu_out2 <= alu_out[31:0];
        end
    end


    always_comb begin
        case (alu_ctrl)
            ALU_ADD : alu_out = exu_in1 + exu_in2;
            ALU_SUB : alu_out = exu_in1 - exu_in2;
            ALU_EQ  : alu_out = (exu_in1 == exu_in2) ? 32'd1 : 32'd0;
            ALU_NE  : alu_out = (exu_in1 != exu_in2) ? 32'd1 : 32'd0;
            ALU_LT  : alu_out = (tmp1 < tmp2) ? 32'd1 : 32'd0;
            ALU_GE  : alu_out = (tmp1 >= tmp2) ? 32'd1 : 32'd0;
            ALU_LE  : alu_out = (tmp1 <= tmp2) ? 32'd1 : 32'd0;
            ALU_GT  : alu_out = (tmp1 > tmp2) ? 32'd1 : 32'd0;
            ALU_AND : alu_out = exu_in1 & exu_in2;
            ALU_OR  : alu_out = exu_in1 | exu_in2;
            ALU_NOR : alu_out = ~(exu_in1 | exu_in2);
            ALU_XOR : alu_out = exu_in1 ^ exu_in2;
            ALU_SLL : alu_out = exu_in2 << exu_in1[4:0];
            ALU_SRL : alu_out = exu_in2 >> exu_in1[4:0];
            ALU_SRA : alu_out = exu_in2 >>> exu_in1[4:0];
            ALU_LTU : alu_out = (exu_in1 < exu_in2) ? 32'd1 : 32'd0;
            ALU_MULT: alu_out = mult;
            ALU_MULTU:alu_out = multu;
            ALU_DIV : alu_out = div;
            ALU_DIVU: alu_out = divu;
            default : alu_out = 32'd0;
        endcase
    end


endmodule
