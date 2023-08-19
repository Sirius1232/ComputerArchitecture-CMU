//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           mips_wbu.sv
// Descriptions:        写回模块
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module mips_wbu (
        input                   clk,
        input                   rst_n,
        input                   wr_en,
        input           [4:0]   wr_gpr,
        input   word_t          wr_data,
        output  mips_state_t    state
    );

    integer i;


    //*****************************************************
    //**                    main code
    //*****************************************************
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for (i=0; i<32; i=i+1) begin
                state.gpr[i] <= 32'd0;
            end
            state.hi <= 32'd0;
            state.lo <= 32'd0;
        end
        else if(wr_en) begin
            if(wr_gpr==`X0)  // X0寄存器为硬件零
                state.gpr[0] <= 32'd0;
            else
                state.gpr[wr_gpr] <= wr_data;
            state.hi <= 32'd0;
            state.lo <= 32'd0;
        end
        else begin
            state <= state;
        end
    end


endmodule
