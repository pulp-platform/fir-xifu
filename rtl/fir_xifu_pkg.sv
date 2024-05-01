/*
 * fir_xifu_pkg.sv
 * Francesco Conti <f.conti@unibo.it>
 *
 * Copyright (C) 2024 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 */

package fir_xifu_pkg;

  // inst[4:2]=110 [6:5]=10 [1:0]=11
  parameter logic [6:0] INSTR_OPCODE = 7'b1011011;

  // I type
  parameter logic [2:0] INSTR_LDTAP_FUNCT3 = 3'b000;
  parameter logic [2:0] INSTR_LDSAM_FUNCT3 = 3'b001;

  // S type
  parameter logic [2:0] INSTR_STSAM_FUNCT3 = 3'b010;

  function automatic logic [2:0] xifu_get_funct3(logic [31:0] in);
    logic [2:0] out;
    out = in[14:12];
    return out;
  endfunction

  function automatic logic [6:0] xifu_get_opcode(logic [31:0] in);
    logic [6:0] out;
    out = in[6:0];
    return out;
  endfunction

  function automatic logic [11:0] xifu_get_immediate_I(logic [31:0] in);
    logic [11:0] out;
    out = in[31:20];
    return out;
  endfunction

  function automatic logic [11:0] xifu_get_immediate_S(logic [31:0] in);
    logic [11:0] out;
    out = {in[31:25], in[11:7]};
    return out;
  endfunction

  function automatic logic [4:0] xifu_get_rs1(logic [31:0] in);
    logic [4:0] out;
    out = in[19:15];
    return out;
  endfunction

  function automatic logic [4:0] xifu_get_rs2(logic [31:0] in);
    logic [4:0] out;
    out = in[24:20];
    return out;
  endfunction

  function automatic logic [4:0] xifu_get_rd(logic [31:0] in);
    logic [4:0] out;
    out = in[11:7];
    return out;
  endfunction

  typedef enum logic[1:0] {
    INSTR_LDTAP : 2'b00,
    INSTR_LDSAM : 2'b01,
    INSTR_STSAM : 2'b11
  } fir_xifu_instr_t;
    
  typedef struct {
    fir_xifu_instr_t instr;
    logic [31:0] base;
    logic [11:0] offset;
    logic        store;
    logic [4:0]  rs1;
    logic [4:0]  rd;
  } fir_xifu_id2ex_t;
    
  typedef struct {
    fir_xifu_instr_t instr;
    logic [31:0] next_addr;
    logic [4:0]  rs1;
    logic [4:0]  rd;
  } fir_xifu_ex2wb_t;

  typedef struct {
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
  } fir_xifu_id2ctrl_t;

  typedef struct {
    logic placeholder
  } fir_xifu_ctrl2id_t;

  typedef struct {
    logic placeholder
  } fir_xifu_ex2ctrl_t;

  typedef struct {
    logic [31:0] sample;
  } fir_xifu_ctrl2ex_t;

  typedef struct {
    logic [31:0] sample;
    logic [31:0] tap;
    logic        valid;
  } fir_xifu_wb2ctrl_t;

  typedef struct {
    logic placeholder
  } fir_xifu_ctrl2wb_t;

endpackage /* fir_xifu_pkg */
