/*
 * fir_xifu_ex.sv
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

module fir_xifu_ex
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*; 
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic clear_i,

  cv32e40x_if_xif.coproc_mem    xif_mem_o,
  
  input  id2ex_t   id2ex_i,
  output ex2wb_t   ex2wb_o,

  output ex2regfile_t ex2regfile_o,
  input  regfile2ex_t regfile2ex_i,

  input  ctrl2ex_t ctrl2ex_i,

  input  wb_fwd_t wb_fwd_i,

  input  logic ready_i,
  output logic ready_o
);

  // Forwarding logic (TODO: move in controller?)
  logic forwarding;
  assign forwarding = wb_fwd_i.we & (wb_fwd_i.rd == id2ex_i.rs1);

  // Compute addresses: this is used for load/store operations, which
  // need to compute the base+offset (with sign extension for the latter)
  // and also the updated address using postincrement.
  logic [31:0] next_addr, curr_addr; 
  assign curr_addr = ~forwarding ? id2ex_i.base : wb_fwd_i.result;
  assign next_addr = curr_addr + signed'(id2ex_i.offset + 32'sh0);
  
  // Issue memory transaction (load or store): currently this is issued
  // immediately for loads and only if a commit signal has arrived for
  // stores (typically in the same EX cycle, at least for CV32E40X).
  // The load/store operation is carried out by the core's LSU.
  always_comb
  begin
    xif_mem_o.mem_req   = '0;
    xif_mem_o.mem_valid = '0;
    if(id2ex_i.instr == INSTR_XFIRSW || id2ex_i.instr == INSTR_XFIRLW) begin
      if(id2ex_i.instr == INSTR_XFIRSW)
        xif_mem_o.mem_valid = ctrl2ex_i.commit[id2ex_i.id]; // do not issue memory requests for non-committed store
      else
        xif_mem_o.mem_valid = 1'b1;
      xif_mem_o.mem_req.id    = id2ex_i.id;
      xif_mem_o.mem_req.addr  = curr_addr;
      xif_mem_o.mem_req.we    = id2ex_i.instr == INSTR_XFIRSW;
      xif_mem_o.mem_req.size  = 3'b100;
      xif_mem_o.mem_req.be    = 4'b1111;
      xif_mem_o.mem_req.wdata = (regfile2ex_i.op_b >>> id2ex_i.rd) * 32'sh1; // the right-shift bits are encoded in Imm[4:0] in S-type, same as RD in R-type
      xif_mem_o.mem_req.last  = 1'b1;
    end
  end

  // Dot product calculation: here we split the operands, extracted from the register
  // file, into 16-bit signed operands and perform the dot-product operation.
  // We use operand gating to (potentially) save a bit of power at the cost of an
  // extra logic layer. Notice the usage of a signed neutral constant (32'sh1) to
  // make sure that the sign-extensions are performed properly.
  logic signed [1:0][15:0] dotp_op_a, dotp_op_b;
  logic signed [1:0][31:0] dotp_prod;
  logic signed [31:0] dotp_op_c, dotp_result;
  assign dotp_op_a = id2ex_i.instr == INSTR_XFIRDOTP ? signed'(regfile2ex_i.op_a) : '0;
  assign dotp_op_b = id2ex_i.instr == INSTR_XFIRDOTP ? signed'(regfile2ex_i.op_b) : '0;
  assign dotp_op_c = id2ex_i.instr == INSTR_XFIRDOTP ? signed'(regfile2ex_i.op_c) : '0;
  assign dotp_prod[0] = (signed'(dotp_op_a[0]) * 32'sh1) * (signed'(dotp_op_b[0]) * 32'sh1);
  assign dotp_prod[1] = (signed'(dotp_op_a[1]) * 32'sh1) * (signed'(dotp_op_b[1]) * 32'sh1);
  assign dotp_result = signed'(dotp_prod[0]) + signed'(dotp_prod[1]) + dotp_op_c;

  // EX/WB pipe stage
  ex2wb_t ex2wb_d;

  always_comb
  begin
    ex2wb_d = '0;
    ex2wb_d.result = id2ex_i.instr == INSTR_XFIRDOTP ? dotp_result : next_addr;
    ex2wb_d.rs1    = id2ex_i.rs1;
    ex2wb_d.rs2    = id2ex_i.rs2;
    ex2wb_d.rd     = id2ex_i.rd;
    ex2wb_d.instr  = id2ex_i.instr;
    ex2wb_d.id     = id2ex_i.id;
  end

  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      ex2wb_o <= '0;
    end
    else if(clear_i) begin
      ex2wb_o <= '0;
    end
    else if(ready_i) begin
      ex2wb_o <= ex2wb_d;
    end
  end

  // to regfile / XIFU reg file
  always_comb
  begin
    ex2regfile_o = '0;
    ex2regfile_o.rs1 = id2ex_i.rs1;
    ex2regfile_o.rs2 = id2ex_i.rs2;
    ex2regfile_o.rd  = id2ex_i.rd;
  end

  // backprop ready
  assign ready_o = ready_i;

endmodule /* fir_xifu_ex */
