`ifndef __MIPS_TYPEDEF_SVH__
`define __MIPS_TYPEDEF_SVH__

typedef enum logic[4:0] {
    ALU_NOP,
    ALU_ADD,    ALU_SUB,    ALU_EQ,     ALU_NE,
    ALU_LT ,    ALU_GE,     ALU_LE,     ALU_GT,
    ALU_AND,    ALU_OR,     ALU_NOR,    ALU_XOR,
    ALU_SLL,    ALU_SRL,    ALU_SRA,    ALU_LTU,
    ALU_MULT,   ALU_MULTU,  ALU_DIV,    ALU_DIVU
} alu_ctrl_t;

typedef enum logic[1:0] {
    HI_EN, LO_EN, GPR_EN, IMM_EN
} data_sel_t;

typedef struct {
    logic   [31:0]  gpr[0:31];
    logic   [31:0]  hi;
    logic   [31:0]  lo;
} mips_state_t;

typedef     logic[31:0]     word_t;
typedef     logic[31:0]     pc_t;
typedef     logic[31:0]     mips_t;

typedef struct packed {
    logic               wr_en;
    logic   [4:0]       wr_gpr;
    logic               wr_hi;
    logic               wr_lo;
} wb_ctrl_t;

typedef struct packed {
    data_sel_t          rs_en;
    logic   [4:0]       rs;
    data_sel_t          rt_en;
    logic   [4:0]       rt;
} gpr_ctrl_t;

typedef struct packed {
    logic               rs_mem;
    logic               rs_wbu;
    logic               rt_mem;
    logic               rt_wbu;
} raw_t;

`endif
