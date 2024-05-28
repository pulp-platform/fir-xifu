/*
 * fir_xifu_wb.sv
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

module fir_xifu_wb
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*; 
(
  input  logic clk_i,
  input  logic rst_ni,

  cv32e40x_if_xif.coproc_mem_result xif_mem_result_i,
  cv32e40x_if_xif.coproc_result     xif_result_o,
  
  input  ex2wb_t   ex2wb_i,

  output wb2regfile_t wb2regfile_o,

  output wb2ctrl_t wb2ctrl_o,
  input  ctrl2wb_t ctrl2wb_i,

  output wb_fwd_t wb_fwd_o,

  output logic kill_o,
  output logic ready_o
);

  // Extract all information on the current instruction status from
  // the scoreboard.
  // If an instruction is killed in WB, all the pipeline needs to be
  // cleared.
  logic commit, issue;
  assign issue  = ctrl2wb_i.issue [ex2wb_i.id];
  assign commit = ctrl2wb_i.commit[ex2wb_i.id];
  assign kill_o = ctrl2wb_i.kill  [ex2wb_i.id];
  
  // Set write-back data info for register-file.
  assign wb2regfile_o.result = '0; // placeholder: what should be written back to XIFU regfile, and under which conditions?
                                   //              this depends on ex2wb_i.instr...
  assign wb2regfile_o.write  = commit; // placeholder: right now, we write back every time we commit: is that right? do all 
                                       //              xfir instructions require to write back something to XIFU register file?
                                       //              you should keep this to 'commit', not 1'b1, in the cases where we want
                                       //              to actually write back :)
  assign wb2regfile_o.rd     = '0; // placeholder: what register should we target for write-back?

  // Save mem_result rdata
  logic [31:0] mem_result_rdata_q;
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni) begin
      mem_result_rdata_q <= '0;
    end
    else if(xif_mem_result_i.mem_result_valid) begin
      mem_result_rdata_q <= xif_mem_result_i.mem_result.rdata;
    end
  end

  // Set flag when there is a valid result, clear if there is no valid result and there is a commit
  logic mem_result_valid_flag, mem_result_valid_q;
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni) begin
      mem_result_valid_q <= '0;
    end
    else if(xif_mem_result_i.mem_result_valid) begin
      mem_result_valid_q <= 1'b1;
    end
    else if(commit) begin
      mem_result_valid_q <= 1'b0;
    end
  end
  assign mem_result_valid_flag = xif_mem_result_i.mem_result_valid | mem_result_valid_q;

  // update base address and signal instruction completion
  always_comb
  begin
    xif_result_o.result = '0;
    xif_result_o.result_valid = '0;
    wb2ctrl_o = '0;
    if(ex2wb_i.instr == INSTR_XFIRSW || ex2wb_i.instr == INSTR_XFIRLW) begin
      xif_result_o.result_valid   = mem_result_valid_flag;
      wb2ctrl_o.clear[ex2wb_i.id] = commit & mem_result_valid_flag;
    end
    else if(ex2wb_i.instr == INSTR_XFIRDOTP) begin
      xif_result_o.result_valid   = 1'b1;
      wb2ctrl_o.clear[ex2wb_i.id] = commit;
    end
    xif_result_o.result.id    = ex2wb_i.id;
    xif_result_o.result.data  = '0; // placeholder: what should we actually write back? this should be used for rd auto-increment
    xif_result_o.result.rd    = '0; // placeholder: this is a bit counterintuitive -- the RD here is the write-back register in the CV32E40X register file.
                                    // check in the specs which register should this one be, but here's one hint: it's not ex2wb_i.rd ;)
    xif_result_o.result.we    = '0; // placeholder: set to 1 only for instructions where we actually write-back to CV32E40X register file.
  end

  // Forward rd and result to EX stage
  assign wb_fwd_o.rd     = xif_result_o.result.rd;
  assign wb_fwd_o.result = xif_result_o.result.data;
  assign wb_fwd_o.we     = xif_result_o.result.we;

  // Back-prop ready: the only condition in which we are not ready is when the current id is issued but not committed yet
  assign ready_o = (issue & ~commit) && ex2wb_i.instr != INSTR_INVALID ? 1'b0 : 1'b1;

endmodule /* fir_xifu_wb */
