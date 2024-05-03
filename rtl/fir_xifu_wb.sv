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
  
  input  fir_xifu_ex2wb_t   ex2wb_i,

  output fir_xifu_wb2regfile_t wb2regfile_o,

  output fir_xifu_wb2ctrl_t wb2ctrl_o,
  input  fir_xifu_ctrl2wb_t ctrl2wb_i,

  output logic kill_o
);

  logic [31:0] rdata;
  assign rdata = xif_mem_result_i.mem_result.rdata;

  logic commit;
  assign commit = ctrl2wb_i.commit[ex2wb_i.id];
  assign kill_o = ctrl2wb_i.kill  [ex2wb_i.id];
  
  assign wb2regfile_o.result = ex2wb_i.instr == INSTR_XFIRLW   ? xif_mem_result_i.mem_result.rdata : ex2wb_i.result;
  assign wb2regfile_o.write  = ex2wb_i.instr == INSTR_XFIRLW || ex2wb_i.instr == INSTR_XFIRDOTP ? commit : 1'b0;
  assign wb2regfile_o.rd     = ex2wb_i.rd;

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
    xif_result_o.result.data  = ex2wb_i.result; // autoincrement
    xif_result_o.result.rd    = ex2wb_i.rs1;
    xif_result_o.result.we    = 1'b1;
  end

endmodule /* fir_xifu_wb */
