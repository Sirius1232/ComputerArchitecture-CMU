`ifndef __MIPS_DEFINES_VH__
`define __MIPS_DEFINES_VH__

`define     SYSCALL     32'h0000_000c
`define     X0          5'd0
`define     X31         5'd31

`define     PC_START    32'h0040_0000


/*opcode*/
`define     SPECIAL     6'h00
`define     REGIMM      6'h01
`define     OP_J        6'h02
`define     OP_JAL      6'h03
`define     OP_BEQ      6'h04
`define     OP_BNE      6'h05
`define     OP_BLEZ     6'h06
`define     OP_BGTZ     6'h07
`define     OP_ADDI     6'h08
`define     OP_ADDIU    6'h09
`define     OP_SLTI     6'h0a
`define     OP_SLTIU    6'h0b
`define     OP_ANDI     6'h0c
`define     OP_ORI      6'h0d
`define     OP_XORI     6'h0e
`define     OP_LUI      6'h0f
`define     OP_LB       6'h20
`define     OP_LH       6'h21
`define     OP_LW       6'h23
`define     OP_LBU      6'h24
`define     OP_LHU      6'h25
`define     OP_SB       6'h28
`define     OP_SH       6'h29
`define     OP_SW       6'h2b

/*Secondary opcodes (funct field; SPECIAL)*/
`define     OP0_SLL     6'h00
`define     OP0_SRL     6'h02
`define     OP0_SRA     6'h03
`define     OP0_SLLV    6'h04
`define     OP0_SRLV    6'h06
`define     OP0_SRAV    6'h07
`define     OP0_JR      6'h08
`define     OP0_JALR    6'h09
`define     OP0_SYSCALL 6'h0c
// `define     OP0_MFHI    6'h10
// `define     OP0_MTHI    6'h11
// `define     OP0_MFLO    6'h12
// `define     OP0_MTLO    6'h13
// `define     OP0_MULT    6'h18
// `define     OP0_MULTU   6'h19
// `define     OP0_DIV     6'h1a
// `define     OP0_DIVU    6'h1b
`define     OP0_ADD     6'h20
`define     OP0_ADDU    6'h21
`define     OP0_SUB     6'h22
`define     OP0_SUBU    6'h23
`define     OP0_AND     6'h24
`define     OP0_OR      6'h25
`define     OP0_XOR     6'h26
`define     OP0_NOR     6'h27
`define     OP0_SLT     6'h2a
`define     OP0_SLTU    6'h2b

/*Secondary opcodes (rt field; REGIMM)*/
`define     OP1_BLTZ    5'h00
`define     OP1_BGEZ    5'h01
`define     OP1_BLTZAL  5'h10
`define     OP1_BGEZAL  5'h11

`endif