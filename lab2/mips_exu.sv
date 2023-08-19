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
        input   alu_ctrl_t      alu_ctrl,
        input   word_t          exu_in1,
        input   word_t          exu_in2,
        output  word_t          exu_out
    );

    word_t              tmp1, tmp2;
    assign  tmp1 = {~exu_in1[31], exu_in1[30:0]};
    assign  tmp2 = {~exu_in2[31], exu_in2[30:0]};


    //*****************************************************
    //**                    main code
    //*****************************************************
    always_comb begin
        case (alu_ctrl)
            ALU_ADD : exu_out = exu_in1 + exu_in2;
            ALU_SUB : exu_out = exu_in1 - exu_in2;
            ALU_EQ  : exu_out = (exu_in1 == exu_in2) ? 32'd1 : 32'd0;
            ALU_NE  : exu_out = (exu_in1 != exu_in2) ? 32'd1 : 32'd0;
            ALU_LT  : exu_out = (tmp1 < tmp2) ? 32'd1 : 32'd0;
            ALU_GE  : exu_out = (tmp1 >= tmp2) ? 32'd1 : 32'd0;
            ALU_LE  : exu_out = (tmp1 <= tmp2) ? 32'd1 : 32'd0;
            ALU_GT  : exu_out = (tmp1 > tmp2) ? 32'd1 : 32'd0;
            ALU_AND : exu_out = exu_in1 & exu_in2;
            ALU_OR  : exu_out = exu_in1 | exu_in2;
            ALU_NOR : exu_out = ~(exu_in1 | exu_in2);
            ALU_XOR : exu_out = exu_in1 ^ exu_in2;
            ALU_SLL : exu_out = exu_in2 << exu_in1[4:0];
            ALU_SRL : exu_out = exu_in2 >> exu_in1[4:0];
            ALU_SRA : exu_out = exu_in2 >>> exu_in1[4:0];
            ALU_LTU : exu_out = (exu_in1 < exu_in2) ? 32'd1 : 32'd0;
            default     : exu_out = 32'd0;
        endcase
    end


endmodule
