`include "../../sources_1/new/mips_defines.vh"
`include "../../sources_1/new/mips_typedef.svh"

`timescale 1ns / 1ns

module tb_cpu_mips();
    /*System Port*/
    logic               clk;
    logic               rst_n;
    logic               start_flag;
    pc_t                lc;
    mips_t              instruction;
    logic   [31:0]      mem[0:1023];

    integer             n;
    integer             fp_r;

    //----------------Module Instantiation----------------
    cpu_mips cpu_mips_inst(
        .clk            (clk),
        .rst_n          (rst_n),
        .start_flag     (start_flag),
        .lc             (lc),
        .n              (n),
        .instr_load     (instruction)
    );

    //----------------Test Conditions----------------
    initial begin
        n=0;
        fp_r = $fopen("E:/VSCodeProject/project_c/lab1/inputs/code.hex", "r");
        while(!$feof(fp_r)) begin
            $fscanf(fp_r, "%h", mem[n]);  // 每次读一行
            n = n + 1;
        end   
        $fclose(fp_r);  // 关闭文件
    end
    assign  instruction = mem[lc[31:2]];

    initial begin
            clk <= 1'b1;
            rst_n <= 1'b0;
            start_flag <= 1'b0;
        #15
            rst_n <= 1'b1;
        #85
            start_flag <= 1'b1;
        #20
            start_flag <= 1'b0;
        #1880
            $stop;
    end

    always  #10 clk=~clk;   //clock period 20ns, 50MHz

endmodule
