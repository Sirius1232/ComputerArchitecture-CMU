#include <stdio.h>
#include "shell.h"

/*立即数符号扩展*/
uint32_t sext(uint32_t imm, uint32_t n)
{
    /*n为imm的位宽*/
    uint32_t imm32, tmp;
    tmp = imm & (0xffffffff >> (32 - n));
    tmp = (1 << (32 - n)) - (tmp >> (n - 1));
    imm32 = (tmp << n) + imm;
    return imm32;
}

void process_instruction()
{
    /* execute one instruction here. You should use CURRENT_STATE and modify
     * values in NEXT_STATE. You can call mem_read_32() and mem_write_32() to
     * access memory. */
    uint32_t instruction = mem_read_32(CURRENT_STATE.PC);
    uint32_t op = instruction >> 26;
    uint32_t funct = instruction & 0x3f;
    uint32_t rs = (instruction >> 21) & 0x1f;
    uint32_t rt = (instruction >> 16) & 0x1f;
    uint32_t rd = (instruction >> 11) & 0x1f;
    uint32_t imm = instruction & 0xffff;
    uint32_t shamt = (instruction >> 6) & 0x1f;
    uint32_t target = instruction & 0x3ffffff;
    uint32_t tmp, addr, mem1, mem0;
    switch (op)
    {
    case 000: // special
    {
        switch (funct)
        {
        case 014: // SYSCALL
            RUN_BIT = FALSE;
            break;
        case 000: // SLL
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rt] << shamt;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 002: // SRL
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rt] >> shamt;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 003: // SRA
            NEXT_STATE.REGS[rd] = (signed)CURRENT_STATE.REGS[rt] >> shamt;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 004: // SLLV
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rt] << (CURRENT_STATE.REGS[rs] & 0x1f);
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 006: // SRLV
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rt] >> (CURRENT_STATE.REGS[rs] & 0x1f);
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 007: // SRAV
            NEXT_STATE.REGS[rd] = (signed)CURRENT_STATE.REGS[rt] >> (CURRENT_STATE.REGS[rs] & 0x1f);
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 011: // JALR
            NEXT_STATE.REGS[rd] = CURRENT_STATE.PC + 4;
        case 010: // JR
            NEXT_STATE.PC = CURRENT_STATE.REGS[rs];
            break;
        case 020: // MFHI
            NEXT_STATE.REGS[rd] = CURRENT_STATE.HI;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 021: // MTHI
            NEXT_STATE.HI = CURRENT_STATE.REGS[rs];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 022: // MFLO
            NEXT_STATE.REGS[rd] = CURRENT_STATE.LO;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 023: // MTLO
            NEXT_STATE.LO = CURRENT_STATE.REGS[rs];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 030: // MULT
            NEXT_STATE.LO = (int32_t)CURRENT_STATE.REGS[rs] * (int32_t)CURRENT_STATE.REGS[rt];
            NEXT_STATE.HI = (int64_t)((int32_t)CURRENT_STATE.REGS[rs] * (int32_t)CURRENT_STATE.REGS[rt]) >> 32;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 031: // MULTU
            NEXT_STATE.LO = CURRENT_STATE.REGS[rs] * CURRENT_STATE.REGS[rt];
            NEXT_STATE.HI = (uint64_t)(CURRENT_STATE.REGS[rs] * CURRENT_STATE.REGS[rt]) >> 32;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 032: // DIV
            NEXT_STATE.LO = (int32_t)CURRENT_STATE.REGS[rs] / (int32_t)CURRENT_STATE.REGS[rt];
            NEXT_STATE.HI = (int32_t)CURRENT_STATE.REGS[rs] % (int32_t)CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 033: // DIVU
            NEXT_STATE.LO = CURRENT_STATE.REGS[rs] / CURRENT_STATE.REGS[rt];
            NEXT_STATE.HI = CURRENT_STATE.REGS[rs] % CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 040: // ADD
        case 041: // ADDU
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rs] + CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 042: // SUB
        case 043: // SUBU
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rs] - CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 044: // AND
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rs] & CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 045: // OR
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rs] | CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 046: // XOR
            NEXT_STATE.REGS[rd] = CURRENT_STATE.REGS[rs] ^ CURRENT_STATE.REGS[rt];
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 047: // NOR
            NEXT_STATE.REGS[rd] = ~(CURRENT_STATE.REGS[rs] | CURRENT_STATE.REGS[rt]);
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 052: // SLT
            if ((signed)CURRENT_STATE.REGS[rs] < (signed)CURRENT_STATE.REGS[rt])
                NEXT_STATE.REGS[rd] = 1;
            else
                NEXT_STATE.REGS[rd] = 0;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 053: // SLTU
            if (CURRENT_STATE.REGS[rs] < CURRENT_STATE.REGS[rt])
                NEXT_STATE.REGS[rd] = 1;
            else
                NEXT_STATE.REGS[rd] = 0;
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        default:
            printf("opcode = %d\n", op);
            printf("The instruction '%08x' is not defined!\n\n", instruction);
            break;
        }
        break;
    }
    case 001: // regimm
    {
        switch (rt)
        {
        case 16: // BLTZAL
            NEXT_STATE.REGS[31] = CURRENT_STATE.PC + 4;
        case 0: // BLTZ
            if ((signed)CURRENT_STATE.REGS[rs] < 0)
                NEXT_STATE.PC = CURRENT_STATE.PC + sext(imm << 2, 18);
            else
                NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        case 17: // BGEZAL
            NEXT_STATE.REGS[31] = CURRENT_STATE.PC + 4;
        case 1: // BGEZ
            if ((signed)CURRENT_STATE.REGS[rs] >= 0)
                NEXT_STATE.PC = CURRENT_STATE.PC + sext(imm << 2, 18);
            else
                NEXT_STATE.PC = CURRENT_STATE.PC + 4;
            break;
        default:
            printf("opcode = %d\n", op);
            printf("The instruction '%08x' is not defined!\n\n", instruction);
            break;
        }
        break;
    }
    case 003: // JAL
        NEXT_STATE.REGS[31] = CURRENT_STATE.PC + 4;
    case 002: // J
        tmp = CURRENT_STATE.PC & 0xf0000000;
        NEXT_STATE.PC = tmp | (target << 2);
        break;
    case 004: // BEQ
        if (CURRENT_STATE.REGS[rs] == CURRENT_STATE.REGS[rt])
            NEXT_STATE.PC = CURRENT_STATE.PC + sext(imm << 2, 18);
        else
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 005: // BNE
        if (CURRENT_STATE.REGS[rs] != CURRENT_STATE.REGS[rt])
            NEXT_STATE.PC = CURRENT_STATE.PC + sext(imm << 2, 18);
        else
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 006: // BLEZ
        if ((signed)CURRENT_STATE.REGS[rs] <= 0)
            NEXT_STATE.PC = CURRENT_STATE.PC + sext(imm << 2, 18);
        else
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 007: // BGTZ
        if ((signed)CURRENT_STATE.REGS[rs] > 0)
            NEXT_STATE.PC = CURRENT_STATE.PC + sext(imm << 2, 18);
        else
            NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 010: // ADDI
    case 011: // ADDIU
        NEXT_STATE.REGS[rt] = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 012: // SLTI
        if ((signed)CURRENT_STATE.REGS[rs] < (signed)sext(imm, 16))
            NEXT_STATE.REGS[rt] = 1;
        else
            NEXT_STATE.REGS[rt] = 0;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 013: // SLTIU
        if (CURRENT_STATE.REGS[rs] < sext(imm, 16))
            NEXT_STATE.REGS[rt] = 1;
        else
            NEXT_STATE.REGS[rt] = 0;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 014: // ANDI
        NEXT_STATE.REGS[rt] = CURRENT_STATE.REGS[rs] & imm;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 015: // ORI
        NEXT_STATE.REGS[rt] = CURRENT_STATE.REGS[rs] | imm;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 016: // XORI
        NEXT_STATE.REGS[rt] = CURRENT_STATE.REGS[rs] ^ imm;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 017: // LUI
        NEXT_STATE.REGS[rt] = imm << 16;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 040: // LB
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr);
        NEXT_STATE.REGS[rt] = sext(tmp & 0x000000ff, 8);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 041: // LH
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr);
        NEXT_STATE.REGS[rt] = sext(tmp & 0x0000ffff, 16);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 043: // LW
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr);
        NEXT_STATE.REGS[rt] = tmp;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 044: // LBU
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr);
        NEXT_STATE.REGS[rt] = tmp & 0x000000ff;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 045: // LHU
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr);
        NEXT_STATE.REGS[rt] = tmp & 0x0000ffff;
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 050: // SB
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr) & 0xff000000 | CURRENT_STATE.REGS[rt] & 0x00ffffff;
        mem_write_32(addr, tmp);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 051: // SH
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = mem_read_32(addr) & 0xffff0000 | CURRENT_STATE.REGS[rt] & 0x0000ffff;
        mem_write_32(addr, tmp);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    case 053: // SW
        addr = CURRENT_STATE.REGS[rs] + sext(imm, 16);
        tmp = CURRENT_STATE.REGS[rt];
        mem_write_32(addr, tmp);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    default:
        printf("opcode = %d\n", op);
        printf("The instruction '%08x' is not defined!\n\n", instruction);
        NEXT_STATE.PC = CURRENT_STATE.PC + 4;
        break;
    }
    NEXT_STATE.REGS[0] = 0;
    return;
}
