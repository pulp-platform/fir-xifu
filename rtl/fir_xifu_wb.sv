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

  output fir_xifu_wb2ctrl_t wb2ctrl_o,
  input  fir_xifu_ctrl2wb_t ctrl2wb_i
);

  logic [31:0] rdata;
  assign rdata = xif_mem_result_i.mem_result.rdata;

  assign wb2ctrl_o.sample = xif_mem_result_i.mem_result.rdata;
  assign wb2ctrl_o.instr  = ex2wb_i.instr;
  assign wb2ctrl_o.valid  = xif_mem_result_i.mem_result_valid;

  // update base address
  always_comb
  begin
    xif_result_o.result_valid = xif_mem_result_i.mem_result_valid;
    xif_result_o.result = '0;
    xif_result_o.result.id    = xif_mem_result_i.mem_result.id;
    xif_result_o.result.data  = ex2wb_i.next_addr;
    xif_result_o.result.rd    = ex2wb_i.register;
    xif_result_o.result.we    = ex2wb_i.instr == INSTR_STSAM ? 1'b1 : 1'b0;
  end

endmodule /* fir_xifu_wb */
