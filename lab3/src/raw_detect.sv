//****************************************************************************************//
// Encoding:            UTF-8
//----------------------------------------------------------------------------------------
// File Name:           raw_detect.sv
// Descriptions:        RAW数据冲突问题检测
//-----------------------------------------README-----------------------------------------
// 
// 
//----------------------------------------------------------------------------------------
//****************************************************************************************//

`include "mips_defines.vh"
`include "mips_typedef.svh"

module raw_detect (
        input   gpr_ctrl_t      gpr_ctrl,
        input   wb_ctrl_t       wb_ctrl_d0,
        input   wb_ctrl_t       wb_ctrl_d1,
        output  raw_t           raw
    );


    always_comb begin
        if ((gpr_ctrl.rs_en==HI_EN && wb_ctrl_d0.wr_hi) || 
            (gpr_ctrl.rs_en==LO_EN && wb_ctrl_d0.wr_lo) || 
            (gpr_ctrl.rs_en==GPR_EN && wb_ctrl_d0.wr_en && gpr_ctrl.rs==wb_ctrl_d0.wr_gpr && gpr_ctrl.rs!=`X0))
            raw.rs_mem = 1'b1;
        else
            raw.rs_mem = 1'b0;
        if ((gpr_ctrl.rs_en==HI_EN && wb_ctrl_d1.wr_hi) || 
            (gpr_ctrl.rs_en==LO_EN && wb_ctrl_d1.wr_lo) || 
            (gpr_ctrl.rs_en==GPR_EN && wb_ctrl_d1.wr_en && gpr_ctrl.rs==wb_ctrl_d1.wr_gpr && gpr_ctrl.rs!=`X0))
            raw.rs_wbu = 1'b1;
        else
            raw.rs_wbu = 1'b0;
        if ((gpr_ctrl.rt_en==HI_EN && wb_ctrl_d0.wr_hi) || 
            (gpr_ctrl.rt_en==LO_EN && wb_ctrl_d0.wr_lo) || 
            (gpr_ctrl.rt_en==GPR_EN && wb_ctrl_d0.wr_en && gpr_ctrl.rt==wb_ctrl_d0.wr_gpr && gpr_ctrl.rt!=`X0))
            raw.rt_mem = 1'b1;
        else
            raw.rt_mem = 1'b0;
        if ((gpr_ctrl.rt_en==HI_EN && wb_ctrl_d1.wr_hi) || 
            (gpr_ctrl.rt_en==LO_EN && wb_ctrl_d1.wr_lo) || 
            (gpr_ctrl.rt_en==GPR_EN && wb_ctrl_d1.wr_en && gpr_ctrl.rt==wb_ctrl_d1.wr_gpr && gpr_ctrl.rt!=`X0))
            raw.rt_wbu = 1'b1;
        else
            raw.rt_wbu = 1'b0;
    end


endmodule
