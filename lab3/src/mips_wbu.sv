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
        input   wb_ctrl_t       wb_ctrl,
        input   word_t          wr_data1,
        input   word_t          wr_data2,
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
        else if(wb_ctrl.wr_en) begin
            if(wb_ctrl.wr_gpr==`X0)  // X0寄存器为硬件零
                state.gpr[0] <= 32'd0;
            else
                state.gpr[wb_ctrl.wr_gpr] <= wr_data1;
            if(wb_ctrl.wr_hi)
                state.hi <= wr_data1;
            else
                state.hi <= state.hi;
            if(wb_ctrl.wr_lo)
                state.lo <= wr_data2;
            else
                state.lo <= state.lo;
        end
        else begin
            state <= state;
        end
    end


endmodule
