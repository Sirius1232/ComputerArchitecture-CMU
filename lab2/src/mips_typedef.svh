`ifndef __MIPS_TYPEDEF_SVH__
`define __MIPS_TYPEDEF_SVH__

typedef enum logic[4:0] {
    ALU_NOP,
    ALU_ADD, ALU_SUB, ALU_EQ , ALU_NE ,
    ALU_LT , ALU_GE , ALU_LE , ALU_GT ,
    ALU_AND, ALU_OR , ALU_NOR, ALU_XOR,
    ALU_SLL, ALU_SRL, ALU_SRA, ALU_LTU
} alu_ctrl_t;

typedef struct {
    logic   [31:0]  gpr[0:31];
    logic   [31:0]  hi;
    logic   [31:0]  lo;
} mips_state_t;

typedef     logic[31:0]     word_t;
typedef     logic[31:0]     pc_t;
typedef     logic[31:0]     mips_t;

`endif
