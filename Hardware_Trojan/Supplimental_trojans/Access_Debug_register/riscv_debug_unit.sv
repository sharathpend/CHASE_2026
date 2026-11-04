// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

////////////////////////////////////////////////////////////////////////////////
// Engineer:       Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Design Name:    Debug Unit                                                 //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Debug controller                                           //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps


////////////////////////////////////////////////
//    ___         ____          _             //
//   / _ \ _ __  / ___|___   __| | ___  ___   //
//  | | | | '_ \| |   / _ \ / _` |/ _ \/ __|  //
//  | |_| | |_) | |__| (_) | (_| |  __/\__ \  //
//   \___/| .__/ \____\___/ \__,_|\___||___/  //
//        |_|                                 //
////////////////////////////////////////////////

parameter OPCODE_SYSTEM    = 7'h73;
parameter OPCODE_FENCE     = 7'h0f;
parameter OPCODE_OP        = 7'h33;
parameter OPCODE_OPIMM     = 7'h13;
parameter OPCODE_STORE     = 7'h23;
parameter OPCODE_LOAD      = 7'h03;
parameter OPCODE_BRANCH    = 7'h63;
parameter OPCODE_JALR      = 7'h67;
parameter OPCODE_JAL       = 7'h6f;
parameter OPCODE_AUIPC     = 7'h17;
parameter OPCODE_LUI       = 7'h37;
parameter OPCODE_OP_FP     = 7'h53;
parameter OPCODE_OP_FMADD  = 7'h43;
parameter OPCODE_OP_FNMADD = 7'h4f;
parameter OPCODE_OP_FMSUB  = 7'h47;
parameter OPCODE_OP_FNMSUB = 7'h4b;
parameter OPCODE_STORE_FP  = 7'h27;
parameter OPCODE_LOAD_FP   = 7'h07;

// those opcodes are now used for PULP custom instructions
// parameter OPCODE_CUST0     = 7'h0b
// parameter OPCODE_CUST1     = 7'h2b

// PULP custom
parameter OPCODE_LOAD_POST  = 7'h0b;
parameter OPCODE_STORE_POST = 7'h2b;
parameter OPCODE_PULP_OP    = 7'h5b;
parameter OPCODE_VECOP      = 7'h57;
parameter OPCODE_HWLOOP     = 7'h7b;

parameter REGC_S1   = 2'b10;
parameter REGC_S4   = 2'b00;
parameter REGC_RD   = 2'b01;
parameter REGC_ZERO = 2'b11;


//////////////////////////////////////////////////////////////////////////////
//      _    _    _   _    ___                       _   _                  //
//     / \  | |  | | | |  / _ \ _ __   ___ _ __ __ _| |_(_) ___  _ __  ___  //
//    / _ \ | |  | | | | | | | | '_ \ / _ \ '__/ _` | __| |/ _ \| '_ \/ __| //
//   / ___ \| |__| |_| | | |_| | |_) |  __/ | | (_| | |_| | (_) | | | \__ \ //
//  /_/   \_\_____\___/   \___/| .__/ \___|_|  \__,_|\__|_|\___/|_| |_|___/ //
//                             |_|                                          //
//////////////////////////////////////////////////////////////////////////////

parameter ALU_OP_WIDTH = 7;

parameter ALU_ADD   = 7'b0011000;
parameter ALU_SUB   = 7'b0011001;
parameter ALU_ADDU  = 7'b0011010;
parameter ALU_SUBU  = 7'b0011011;
parameter ALU_ADDR  = 7'b0011100;
parameter ALU_SUBR  = 7'b0011101;
parameter ALU_ADDUR = 7'b0011110;
parameter ALU_SUBUR = 7'b0011111;

parameter ALU_XOR   = 7'b0101111;
parameter ALU_OR    = 7'b0101110;
parameter ALU_AND   = 7'b0010101;

// Shifts
parameter ALU_SRA   = 7'b0100100;
parameter ALU_SRL   = 7'b0100101;
parameter ALU_ROR   = 7'b0100110;
parameter ALU_SLL   = 7'b0100111;

// bit manipulation
parameter ALU_BEXT  = 7'b0101000;
parameter ALU_BEXTU = 7'b0101001;
parameter ALU_BINS  = 7'b0101010;
parameter ALU_BCLR  = 7'b0101011;
parameter ALU_BSET  = 7'b0101100;

// Bit counting
parameter ALU_FF1   = 7'b0110110;
parameter ALU_FL1   = 7'b0110111;
parameter ALU_CNT   = 7'b0110100;
parameter ALU_CLB   = 7'b0110101;

// Sign-/zero-extensions
parameter ALU_EXTS  = 7'b0111110;
parameter ALU_EXT   = 7'b0111111;

// Comparisons
parameter ALU_LTS   = 7'b0000000;
parameter ALU_LTU   = 7'b0000001;
parameter ALU_LES   = 7'b0000100;
parameter ALU_LEU   = 7'b0000101;
parameter ALU_GTS   = 7'b0001000;
parameter ALU_GTU   = 7'b0001001;
parameter ALU_GES   = 7'b0001010;
parameter ALU_GEU   = 7'b0001011;
parameter ALU_EQ    = 7'b0001100;
parameter ALU_NE    = 7'b0001101;

// Set Lower Than operations
parameter ALU_SLTS  = 7'b0000010;
parameter ALU_SLTU  = 7'b0000011;
parameter ALU_SLETS = 7'b0000110;
parameter ALU_SLETU = 7'b0000111;

// Absolute value
parameter ALU_ABS   = 7'b0010100;
parameter ALU_CLIP  = 7'b0010110;
parameter ALU_CLIPU = 7'b0010111;

// Insert/extract
parameter ALU_INS   = 7'b0101101;

// min/max
parameter ALU_MIN   = 7'b0010000;
parameter ALU_MINU  = 7'b0010001;
parameter ALU_MAX   = 7'b0010010;
parameter ALU_MAXU  = 7'b0010011;

// div/rem
parameter ALU_DIVU  = 7'b0110000; // bit 0 is used for signed mode, bit 1 is used for remdiv
parameter ALU_DIV   = 7'b0110001; // bit 0 is used for signed mode, bit 1 is used for remdiv
parameter ALU_REMU  = 7'b0110010; // bit 0 is used for signed mode, bit 1 is used for remdiv
parameter ALU_REM   = 7'b0110011; // bit 0 is used for signed mode, bit 1 is used for remdiv

parameter ALU_SHUF  = 7'b0111010;
parameter ALU_SHUF2 = 7'b0111011;
parameter ALU_PCKLO = 7'b0111000;
parameter ALU_PCKHI = 7'b0111001;

// fpu
parameter ALU_FKEEP   = 7'b1111111;   // hack, to support fcvt.s.d
parameter ALU_FSGNJ   = 7'b1000000;
parameter ALU_FSGNJN  = 7'b1000001;
parameter ALU_FSGNJX  = 7'b1000010;
parameter ALU_FEQ     = 7'b1000011;
parameter ALU_FLT     = 7'b1000100;
parameter ALU_FLE     = 7'b1000101;
parameter ALU_FMAX    = 7'b1000110;
parameter ALU_FMIN    = 7'b1000111;
parameter ALU_FCLASS  = 7'b1001000;

parameter MUL_MAC32 = 3'b000;
parameter MUL_MSU32 = 3'b001;
parameter MUL_I     = 3'b010;
parameter MUL_IR    = 3'b011;
parameter MUL_DOT8  = 3'b100;
parameter MUL_DOT16 = 3'b101;
parameter MUL_H     = 3'b110;

// vector modes
parameter VEC_MODE32 = 2'b00;
parameter VEC_MODE16 = 2'b10;
parameter VEC_MODE8  = 2'b11;

/////////////////////////////////////////////////////////
//    ____ ____    ____            _     _             //
//   / ___/ ___|  |  _ \ ___  __ _(_)___| |_ ___ _ __  //
//  | |   \___ \  | |_) / _ \/ _` | / __| __/ _ \ '__| //
//  | |___ ___) | |  _ <  __/ (_| | \__ \ ||  __/ |    //
//   \____|____/  |_| \_\___|\__, |_|___/\__\___|_|    //
//                           |___/                     //
/////////////////////////////////////////////////////////

// CSR operations
parameter CSR_OP_NONE  = 2'b00;
parameter CSR_OP_WRITE = 2'b01;
parameter CSR_OP_SET   = 2'b10;
parameter CSR_OP_CLEAR = 2'b11;


// SPR for debugger, not accessible by CPU
parameter SP_DVR0       = 16'h3000;
parameter SP_DCR0       = 16'h3008;
parameter SP_DMR1       = 16'h3010;
parameter SP_DMR2       = 16'h3011;

parameter SP_DVR_MSB = 8'h00;
parameter SP_DCR_MSB = 8'h01;
parameter SP_DMR_MSB = 8'h02;
parameter SP_DSR_MSB = 8'h04;

// Privileged mode
typedef enum logic[1:0] {
  PRIV_LVL_M = 2'b11,
  PRIV_LVL_H = 2'b10,
  PRIV_LVL_S = 2'b01,
  PRIV_LVL_U = 2'b00
} PrivLvl_t;

///////////////////////////////////////////////
//   ___ ____    ____  _                     //
//  |_ _|  _ \  / ___|| |_ __ _  __ _  ___   //
//   | || | | | \___ \| __/ _` |/ _` |/ _ \  //
//   | || |_| |  ___) | || (_| | (_| |  __/  //
//  |___|____/  |____/ \__\__,_|\__, |\___|  //
//                              |___/        //
///////////////////////////////////////////////

// forwarding operand mux
parameter SEL_REGFILE      = 2'b00;
parameter SEL_FW_EX        = 2'b01;
parameter SEL_FW_WB        = 2'b10;

// operand a selection
parameter OP_A_REGA_OR_FWD = 3'b000;
parameter OP_A_CURRPC      = 3'b001;
parameter OP_A_IMM         = 3'b010;
parameter OP_A_REGB_OR_FWD = 3'b011;
parameter OP_A_REGC_OR_FWD = 3'b100;

// immediate a selection
parameter IMMA_Z      = 1'b0;
parameter IMMA_ZERO   = 1'b1;

// operand b selection
parameter OP_B_REGB_OR_FWD = 3'b000;
parameter OP_B_REGC_OR_FWD = 3'b001;
parameter OP_B_IMM         = 3'b010;
parameter OP_B_REGA_OR_FWD = 3'b011;
parameter OP_B_BMASK       = 3'b100;

// immediate b selection
parameter IMMB_I      = 4'b0000;
parameter IMMB_S      = 4'b0001;
parameter IMMB_U      = 4'b0010;
parameter IMMB_PCINCR = 4'b0011;
parameter IMMB_S2     = 4'b0100;
parameter IMMB_S3     = 4'b0101;
parameter IMMB_VS     = 4'b0110;
parameter IMMB_VU     = 4'b0111;
parameter IMMB_SHUF   = 4'b1000;
parameter IMMB_CLIP   = 4'b1001;
parameter IMMB_BI     = 4'b1011;

// bit mask selection
parameter BMASK_A_ZERO = 1'b0;
parameter BMASK_A_S3   = 1'b1;

parameter BMASK_B_S2   = 2'b00;
parameter BMASK_B_S3   = 2'b01;
parameter BMASK_B_ZERO = 2'b10;
parameter BMASK_B_ONE  = 2'b11;

parameter BMASK_A_REG  = 1'b0;
parameter BMASK_A_IMM  = 1'b1;
parameter BMASK_B_REG  = 1'b0;
parameter BMASK_B_IMM  = 1'b1;


// multiplication immediates
parameter MIMM_ZERO    = 1'b0;
parameter MIMM_S3      = 1'b1;

// operand c selection
parameter OP_C_REGC_OR_FWD = 2'b00;
parameter OP_C_REGB_OR_FWD = 2'b01;
parameter OP_C_JT          = 2'b10;

// branch types
parameter BRANCH_NONE = 2'b00;
parameter BRANCH_JAL  = 2'b01;
parameter BRANCH_JALR = 2'b10;
parameter BRANCH_COND = 2'b11; // conditional branches

// jump target mux
parameter JT_JAL  = 2'b01;
parameter JT_JALR = 2'b10;
parameter JT_COND = 2'b11;


///////////////////////////////////////////////
//   ___ _____   ____  _                     //
//  |_ _|  ___| / ___|| |_ __ _  __ _  ___   //
//   | || |_    \___ \| __/ _` |/ _` |/ _ \  //
//   | ||  _|    ___) | || (_| | (_| |  __/  //
//  |___|_|     |____/ \__\__,_|\__, |\___|  //
//                              |___/        //
///////////////////////////////////////////////

// PC mux selector defines
parameter PC_BOOT          = 3'b000;
parameter PC_JUMP          = 3'b010;
parameter PC_BRANCH        = 3'b011;
parameter PC_EXCEPTION     = 3'b100;
parameter PC_ERET          = 3'b101;
parameter PC_DBG_NPC       = 3'b111;

// Exception PC mux selector defines
parameter EXC_PC_ILLINSN   = 2'b00;
parameter EXC_PC_ECALL     = 2'b01;
parameter EXC_PC_LOAD      = 2'b10;
parameter EXC_PC_STORE     = 2'b10;
parameter EXC_PC_IRQ       = 2'b11;

// Exception Cause
parameter EXC_CAUSE_ILLEGAL_INSN = 6'h02;
parameter EXC_CAUSE_BREAKPOINT   = 6'h03;
parameter EXC_CAUSE_ECALL_UMODE  = 6'h08;
parameter EXC_CAUSE_ECALL_MMODE  = 6'h0B;

// Trap mux selector
parameter TRAP_MACHINE      = 1'b0;
parameter TRAP_USER         = 1'b1;

// Exceptions offsets
// target address = {boot_addr[31:8], EXC_OFF} (boot_addr must be 32 BYTE aligned!)
// offset 00 to 7e is used for external interrupts
parameter EXC_OFF_RST      = 8'h80;
parameter EXC_OFF_ILLINSN  = 8'h84;
parameter EXC_OFF_ECALL    = 8'h88;
parameter EXC_OFF_LSUERR   = 8'h8c;


// Debug module
parameter DBG_SETS_W = 6;

parameter DBG_SETS_IRQ    = 5;
parameter DBG_SETS_ECALL  = 4;
parameter DBG_SETS_EILL   = 3;
parameter DBG_SETS_ELSU   = 2;
parameter DBG_SETS_EBRK   = 1;
parameter DBG_SETS_SSTE   = 0;

parameter DBG_CAUSE_HALT   = 6'h1F;

// private FPU
parameter C_CMD               = 4;
parameter C_FPU_ADD_CMD       = 4'h0;
parameter C_FPU_SUB_CMD       = 4'h1;
parameter C_FPU_MUL_CMD       = 4'h2;
parameter C_FPU_DIV_CMD       = 4'h3;
parameter C_FPU_I2F_CMD       = 4'h4;
parameter C_FPU_F2I_CMD       = 4'h5;
parameter C_FPU_SQRT_CMD      = 4'h6;
parameter C_FPU_NOP_CMD       = 4'h7;
parameter C_FPU_FMADD_CMD     = 4'h8;
parameter C_FPU_FMSUB_CMD     = 4'h9;
parameter C_FPU_FNMADD_CMD    = 4'hA;
parameter C_FPU_FNMSUB_CMD    = 4'hB;

parameter C_FFLAG             = 5;
parameter C_RM                = 3;
parameter C_RM_NEAREST        = 3'h0;
parameter C_RM_TRUNC          = 3'h1;
parameter C_RM_PLUSINF        = 3'h3;
parameter C_RM_MINUSINF       = 3'h2;
parameter C_PC                = 5;


module riscv_debug_unit
(
  input logic         clk,
  input logic         rst_n,

  // Debug Interface
  input  logic        debug_req_i,
  output logic        debug_gnt_o,
  output logic        debug_rvalid_o,
  input  logic [14:0] debug_addr_i,
  input  logic        debug_we_i,
  input  logic [31:0] debug_wdata_i,
  output logic [31:0] debug_rdata_o,

  output logic        debug_halted_o,
  input  logic        debug_halt_i,
  input  logic        debug_resume_i,

  // signals to core
  output logic [DBG_SETS_W-1:0] settings_o,

  input  logic        trap_i,      // trap found, need to stop the core now
  input  logic [5:0]  exc_cause_i, // if it was a trap, then the exception controller knows more
  output logic        stall_o,     // after we got control, we control the stall signal
  output logic        dbg_req_o,
  input  logic        dbg_ack_i,

  // register file read port
  output logic        regfile_rreq_o,
  output logic [ 5:0] regfile_raddr_o,
  input  logic [31:0] regfile_rdata_i,

  // register file write port
  output logic        regfile_wreq_o,
  output logic [ 5:0] regfile_waddr_o,
  output logic [31:0] regfile_wdata_o,

  // CSR read/write port
  output logic        csr_req_o,
  output logic [11:0] csr_addr_o,
  output logic        csr_we_o,
  output logic [31:0] csr_wdata_o,
  input  logic [31:0] csr_rdata_i,

  // Signals for PPC & NPC register
  input  logic [31:0] pc_if_i,
  input  logic [31:0] pc_id_i,
  input  logic [31:0] pc_ex_i,

  input  logic        data_load_event_i,
  input  logic        instr_valid_id_i,

  input  logic        sleeping_i,

  input  logic        branch_in_ex_i,
  input  logic        branch_taken_i,

  output logic        jump_req_o,
  output logic [31:0] jump_addr_o
);

  enum logic [2:0] {RD_NONE, RD_CSR, RD_GPR, RD_DBGA, RD_DBGS} rdata_sel_q, rdata_sel_n;

  enum logic [0:0] {FIRST, SECOND} state_q, state_n;

  logic [DBG_SETS_W-1:0] settings_q, settings_n;

  // for timing critical register file access we need to keep those in FFs
  logic [14:0] addr_q;
  logic [31:0] wdata_q; // mainly for jumps
  logic        regfile_rreq_q, regfile_rreq_n;
  logic        regfile_fp_sel_q, regfile_fp_sel_n;
  logic        jump_req_q, jump_req_n;

  // not timing critical
  logic        csr_req_q, csr_req_n;
  logic        regfile_wreq;
  logic        regfile_fp_wr;


  enum logic [1:0] {RUNNING, HALT_REQ, HALT} stall_cs, stall_ns;
  logic [31:0] dbg_rdata;
  logic        dbg_resume;
  logic        dbg_halt;
  logic [5:0]  dbg_cause_q, dbg_cause_n;
  logic        dbg_ssth_q,  dbg_ssth_n;

  logic        ssth_clear;


  // ppc/npc tracking
  enum logic [1:0] {IFID, IFEX, IDEX} pc_tracking_fsm_cs, pc_tracking_fsm_ns;
  logic [31:0] ppc_int, npc_int;


  // address decoding, write and read controller
  always_comb
  begin
    rdata_sel_n    = RD_NONE;
    state_n        = FIRST;

    debug_gnt_o    = 1'b0;

    regfile_rreq_n = 1'b0;
    regfile_wreq   = 1'b0;
    csr_req_n      = 1'b0;
    csr_we_o       = 1'b0;
    jump_req_n     = 1'b0;

    dbg_resume     = 1'b0;
    dbg_halt       = 1'b0;
    settings_n     = settings_q;

    ssth_clear     = 1'b0;

    regfile_fp_sel_n = 1'b0;
    regfile_fp_wr    = 1'b0;

    if (debug_req_i) begin
      if (debug_we_i) begin
        //----------------------------------------------------------------------------
        // write access
        //----------------------------------------------------------------------------
        //BUG
        if (debug_addr_i[14]) begin
          // CSR access
          if (state_q == FIRST) begin
            // only grant in second cycle, address and data have been latched by then
            debug_gnt_o = 1'b0;
            state_n     = SECOND;

            if (debug_halted_o) begin
              // access to internal registers are only allowed when the core is halted
              csr_req_n = 1'b1;
            end
          end else begin
            debug_gnt_o = 1'b1; // grant it even when invalid access to not block
            state_n     = FIRST;
            csr_we_o    = 1'b1;
          end
        end else begin
          // non-CSR access
          unique case (debug_addr_i[13:8])
            6'b00_0000: begin // Debug Registers, always accessible
              debug_gnt_o = 1'b1;

              unique case (debug_addr_i[6:2])
                5'b0_0000: begin // DBG_CTRL
                  if (debug_wdata_i[16]) begin
                    // HALT set
                    if (~debug_halted_o) begin
                      // not halt, so STOP
                      dbg_halt = 1'b1;
                    end
                  end else begin
                    // RESUME set
                    if (debug_halted_o) begin
                      dbg_resume = 1'b1;
                    end
                  end

                  settings_n[DBG_SETS_SSTE] = debug_wdata_i[0];
                end
                5'b0_0001: begin // DBG_HIT
                  ssth_clear = debug_wdata_i[0];
                end
                5'b0_0010: begin // DBG_IE
                  settings_n[DBG_SETS_ECALL] = debug_wdata_i[11];
                  settings_n[DBG_SETS_ELSU]  = debug_wdata_i[7] | debug_wdata_i[5];
                  settings_n[DBG_SETS_EBRK]  = debug_wdata_i[3];
                  settings_n[DBG_SETS_EILL]  = debug_wdata_i[2];
                end
                default:;
              endcase
            end

            6'b10_0000: begin // Debug Registers, only accessible when in debug
              debug_gnt_o = 1'b1; // grant it even when invalid access to not block

              if (debug_halted_o) begin
                unique case (debug_addr_i[6:2])
                  5'b0_0000: jump_req_n = 1'b1; // DNPC
                  default:;
                endcase
              end
            end

            6'b00_0100: begin // General-Purpose Registers
              debug_gnt_o = 1'b1; // grant it even when invalid access to not block

              if (debug_halted_o) begin
                regfile_wreq = 1'b1;
              end
            end

            6'b00_0101: begin // General-Purpose Floating-Point Registers
              debug_gnt_o = 1'b1; // grant it even when invalid access to not block

              if (debug_halted_o) begin
                regfile_wreq  = 1'b1;
                regfile_fp_wr = 1'b1;
              end
            end

            default: debug_gnt_o = 1'b1; // grant it even when invalid access to not block
          endcase
        end
      end else begin
        //----------------------------------------------------------------------------
        // read access
        //----------------------------------------------------------------------------
        if (debug_addr_i[14]) begin
          debug_gnt_o = 1'b1; // grant it even when invalid access to not block

          // CSR access
          if (debug_halted_o) begin
            // access to internal registers are only allowed when the core is halted
            csr_req_n   = 1'b1;
            rdata_sel_n = RD_CSR;
          end
        end else begin
          // non-CSR access
          unique case (debug_addr_i[13:8])
            6'b00_0000: begin // Debug Registers, always accessible
              debug_gnt_o = 1'b1;

              rdata_sel_n = RD_DBGA;
            end

            6'b10_0000: begin // Debug Registers, only accessible when in debug
              debug_gnt_o = 1'b1; // grant it even when invalid access to not block

              rdata_sel_n = RD_DBGS;
            end

            6'b00_0100: begin // General-Purpose Registers
              debug_gnt_o = 1'b1; // grant it even when invalid access to not block

              if (debug_halted_o) begin
                regfile_rreq_n = 1'b1;
                rdata_sel_n    = RD_GPR;
              end
            end

            6'b00_0101: begin // General-Purpose Floating-Point Registers
              debug_gnt_o = 1'b1; // grant it even when invalid access to not block

              if (debug_halted_o) begin
                regfile_rreq_n   = 1'b1;
                regfile_fp_sel_n = 1'b1;
                rdata_sel_n      = RD_GPR;
              end
            end
            default: debug_gnt_o = 1'b1; // grant it even when invalid access to not block
          endcase
        end
      end
    end
  end

  //----------------------------------------------------------------------------
  // debug register read access
  //
  // Since those are combinational, we can do it in the cycle where we set
  // rvalid. The address has been latched into addr_q
  //----------------------------------------------------------------------------
  always_comb
  begin
    dbg_rdata = '0;

    case (rdata_sel_q)
      RD_DBGA: begin
        unique case (addr_q[6:2])
          5'h00: dbg_rdata[31:0] = {15'b0, debug_halted_o, 15'b0, settings_q[DBG_SETS_SSTE]}; // DBG_CTRL
          5'h01: dbg_rdata[31:0] = {15'b0, sleeping_i, 15'b0, dbg_ssth_q}; // DBG_HIT
          5'h02: begin // DBG_IE
            dbg_rdata[31:16] = '0;
            dbg_rdata[15:12] = '0;
            dbg_rdata[11]    = settings_q[DBG_SETS_ECALL];
            dbg_rdata[10: 8] = '0;
            dbg_rdata[ 7]    = settings_q[DBG_SETS_ELSU];
            dbg_rdata[ 6]    = 1'b0;
            dbg_rdata[ 5]    = settings_q[DBG_SETS_ELSU];
            dbg_rdata[ 4]    = 1'b0;
            dbg_rdata[ 3]    = settings_q[DBG_SETS_EBRK];
            dbg_rdata[ 2]    = settings_q[DBG_SETS_EILL];
            dbg_rdata[ 1: 0] = '0;
          end
          5'h03: dbg_rdata = {dbg_cause_q[5], 26'b0, dbg_cause_q[4:0]}; // DBG_CAUSE
          5'h10: dbg_rdata = '0; // DBG_BPCTRL0
          5'h12: dbg_rdata = '0; // DBG_BPCTRL1
          5'h14: dbg_rdata = '0; // DBG_BPCTRL2
          5'h16: dbg_rdata = '0; // DBG_BPCTRL3
          5'h18: dbg_rdata = '0; // DBG_BPCTRL4
          5'h1A: dbg_rdata = '0; // DBG_BPCTRL5
          5'h1C: dbg_rdata = '0; // DBG_BPCTRL6
          5'h1E: dbg_rdata = '0; // DBG_BPCTRL7
          default:;
        endcase
      end

      RD_DBGS: begin
        unique case (addr_q[2:2])
          1'b0: dbg_rdata = npc_int; // DBG_NPC
          1'b1: dbg_rdata = ppc_int; // DBG_PPC
          default:;
        endcase
      end

      default:;
    endcase
  end

  //----------------------------------------------------------------------------
  // read data mux
  //----------------------------------------------------------------------------
  always_comb
  begin
    debug_rdata_o = '0;

    case (rdata_sel_q)
      RD_CSR:  debug_rdata_o = csr_rdata_i;
      RD_GPR:  debug_rdata_o = regfile_rdata_i;
      RD_DBGA: debug_rdata_o = dbg_rdata;
      RD_DBGS: debug_rdata_o = dbg_rdata;
    endcase
  end

  //----------------------------------------------------------------------------
  // rvalid generation
  //----------------------------------------------------------------------------
  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n) begin
      debug_rvalid_o <= 1'b0;
    end else begin
      debug_rvalid_o <= debug_gnt_o; // always give the rvalid one cycle after gnt
    end
  end

  //----------------------------------------------------------------------------
  // stall control
  //----------------------------------------------------------------------------
  always_comb
  begin
    stall_ns       = stall_cs;
    dbg_req_o      = 1'b0;
    stall_o        = 1'b0;
    debug_halted_o = 1'b0;
    dbg_cause_n    = dbg_cause_q;
    dbg_ssth_n     = dbg_ssth_q;

    case (stall_cs)
      RUNNING: begin
        dbg_ssth_n = 1'b0;

        if (dbg_halt | debug_halt_i | trap_i) begin
          dbg_req_o   = 1'b1;
          stall_ns    = HALT_REQ;

          if (trap_i) begin
            if (settings_q[DBG_SETS_SSTE])
              dbg_ssth_n = 1'b1;

            dbg_cause_n = exc_cause_i;
          end else begin
            dbg_cause_n = DBG_CAUSE_HALT;
          end
        end
      end

      HALT_REQ: begin
        dbg_req_o = 1'b1;

        if (dbg_ack_i)
          stall_ns = HALT;

        if (dbg_resume | debug_resume_i)
          stall_ns = RUNNING;
      end

      HALT: begin
        stall_o        = 1'b1;
        debug_halted_o = 1'b1;

        if (dbg_resume | debug_resume_i) begin
          stall_ns = RUNNING;
          stall_o  = 1'b0;
        end
      end
    endcase

    if (ssth_clear)
      dbg_ssth_n = 1'b0;
  end

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n) begin
      stall_cs    <= RUNNING;
      dbg_cause_q <= DBG_CAUSE_HALT;
      dbg_ssth_q  <= 1'b0;
    end else begin
      stall_cs    <= stall_ns;
      dbg_cause_q <= dbg_cause_n;
      dbg_ssth_q  <= dbg_ssth_n;
    end
  end

  //----------------------------------------------------------------------------
  // NPC/PPC selection
  //----------------------------------------------------------------------------
  always_comb
  begin
    pc_tracking_fsm_ns = pc_tracking_fsm_cs;

    ppc_int = pc_id_i;
    npc_int = pc_if_i;

    // PPC/NPC mux
    unique case (pc_tracking_fsm_cs)
      IFID: begin
        ppc_int = pc_id_i;
        npc_int = pc_if_i;
      end

      IFEX: begin
        ppc_int = pc_ex_i;
        npc_int = pc_if_i;
      end

      IDEX: begin
        ppc_int = pc_ex_i;
        npc_int = pc_id_i;

        if (jump_req_o)
          pc_tracking_fsm_ns = IFEX;
      end

      default: begin
        pc_tracking_fsm_ns = IFID;
      end
    endcase

    // set state if trap is encountered
    if (dbg_ack_i) begin
      pc_tracking_fsm_ns = IFID;

      if (branch_in_ex_i) begin
        if (branch_taken_i)
          pc_tracking_fsm_ns = IFEX;
        else
          pc_tracking_fsm_ns = IDEX;
      end else if (data_load_event_i) begin
        // for p.elw
        if (instr_valid_id_i)
           pc_tracking_fsm_ns = IDEX;
        else
           pc_tracking_fsm_ns = IFEX;
      end
    end
  end


  always_ff @(posedge clk, negedge rst_n)
  begin
    if (~rst_n) begin
      pc_tracking_fsm_cs <= IFID;

      addr_q             <= '0;
      wdata_q            <= '0;
      state_q            <= FIRST;
      rdata_sel_q        <= RD_NONE;
      regfile_rreq_q     <= 1'b0;
      regfile_fp_sel_q   <= 1'b0;
      csr_req_q          <= 1'b0;
      jump_req_q         <= 1'b0;

      settings_q         <= 1'b0;
    end else begin
      pc_tracking_fsm_cs <= pc_tracking_fsm_ns;

      // settings
      settings_q         <= settings_n;

      // for the actual interface
      if (debug_req_i) begin
        addr_q  <= debug_addr_i;
        wdata_q <= debug_wdata_i;
        state_q <= state_n;
      end

      if (debug_req_i | debug_rvalid_o) begin
        // wait for either req or rvalid to set those FFs
        // This makes sure that they are only triggered once when there is
        // only one request, and the FFs can be properly clock gated otherwise
        regfile_rreq_q   <= regfile_rreq_n;
        regfile_fp_sel_q <= regfile_fp_sel_n;
        csr_req_q        <= csr_req_n;
        jump_req_q       <= jump_req_n;
        rdata_sel_q      <= rdata_sel_n;
      end
    end
  end

  assign regfile_rreq_o  = regfile_rreq_q;
  assign regfile_raddr_o = {regfile_fp_sel_q, addr_q[6:2]};


  assign regfile_wreq_o  = regfile_wreq;
  assign regfile_waddr_o = {regfile_fp_wr,debug_addr_i[6:2]};
  assign regfile_wdata_o = debug_wdata_i;

  assign csr_req_o       = csr_req_q;
  assign csr_addr_o      = addr_q[13:2];
  assign csr_wdata_o     = wdata_q;

  assign jump_req_o      = jump_req_q;
  assign jump_addr_o     = wdata_q;

  assign settings_o      = settings_q;



endmodule // debug_unit
