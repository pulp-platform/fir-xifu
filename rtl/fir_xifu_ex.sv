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

  cv32e40x_if_xif.coproc_issue  xif_issue_i,
  cv32e40x_if_xif.coproc_commit xif_commit_i,
  cv32e40x_if_xif.coproc_mem    xif_mem_o,
  
  input  fir_xifu_id2ex_t   id2ex_i,
  output fir_xifu_ex2wb_t   ex2wb_o,

  output fir_xifu_ex2ctrl_t ex2ctrl_o,
  input  fir_xifu_ctrl2ex_t ctrl2ex_i
);

  // compute address for next iteration
  logic [31:0] next_addr, curr_addr; 
  assign curr_addr = id2ex_i.base + signed'(id2ex_i.offset + 32'sh0);
  assign next_addr = curr_addr + 32'h4;
  
  // issue memory transaction (load or store)
  always_comb
  begin
    xif_mem_o.mem_req   = '0;
    xif_mem_o.mem_valid = '0;
    if(valid_instr) begin
      xif_mem_o.mem_req.id    = xif_issue_i.issue_req.id;
      xif_mem_o.mem_req.addr  = xif_issue_i.issue_req.rs[0];
      xif_mem_o.mem_req.we    = id2ex_i.instr == INSTR_XFIRSW;
      xif_mem_o.mem_req.size  = 3'b100;
      xif_mem_o.mem_req.be    = 4'b1111;
      xif_mem_o.mem_req.wdata = ctrl2ex.sample;
      xif_mem_o.mem_req.last  = 1'b1;
    end
  end

  // dot product calculation (with operand gating)
  logic signed [1:0][15:0] dotp_op_a, dotp_op_b;
  logic signed [31:0] dotp_op_c, dotp_result;
  assign dotp_op_a = id2ex_i.instr == INSTR_XFIRDOTP ? signed'(ctrl2ex_i.op_a) : '0;
  assign dotp_op_b = id2ex_i.instr == INSTR_XFIRDOTP ? signed'(ctrl2ex_i.op_b) : '0;
  assign dotp_op_c = id2ex_i.instr == INSTR_XFIRDOTP ? signed'(ctrl2ex_i.op_c) : '0;
  assign dotp_result = (dotp_op_a[0] * dotp_op_b[0] + dotp_op_a[1] * dotp_op_b[1] * 32'sh1) + dotp_op_c;

  // EX/WB pipe stage
  fir_xifu_ex2wb_t ex2wb_d;

  always_comb
  begin
    ex2wb_d = '0;
    ex2wb_d.result = id2ex_i.instr == INSTR_XFIRDOTP ? dotp_result : next_addr;
    ex2wb_d.rs1    = id2ex_i.rs1;
    ex2wb_d.rd     = id2ex_i.rd;
    ex2wb_d.instr  = id2ex_i.instr;
  end

  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      ex2wb_o <= '0;
    end
    else if (xif_issue_i.issue_valid) begin
      ex2wb_o <= ex2
    end
  end

endmodule /* fir_xifu_ex */
