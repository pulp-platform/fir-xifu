/*
 * fir_xifu_top.sv
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

module fir_xifu_top
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*;
(
  input logic                       clk_i,
  input logic                       rst_ni,
  input logic                       clear_i,
  cv32e40x_if_xif.coproc_issue      xif_issue_i,
  cv32e40x_if_xif.coproc_compressed xif_compressed_i,
  cv32e40x_if_xif.coproc_commit     xif_commit_i,
  cv32e40x_if_xif.coproc_mem        xif_mem_o,
  cv32e40x_if_xif.coproc_mem_result xif_mem_result_i,
  cv32e40x_if_xif.coproc_result     xif_result_o
);

  fir_xifu_id2ctrl_t id2ctrl;
  fir_xifu_ctrl2id_t ctrl2id;
  fir_xifu_ex2ctrl_t ex2ctrl;
  fir_xifu_ctrl2ex_t ctrl2ex;
  fir_xifu_wb2ctrl_t wb2ctrl;
  fir_xifu_ctrl2wb_t ctrl2wb;

  // CV32E40X does not currently support compressed XIF instructions
  assign xif_compressed_i.compressed_ready = 1'b1;
  assign xif_compressed_i.compressed_resp  = '0;

  fir_xifu_id i_id (
    .clk_i            ( clk_i        ),
    .rst_ni           ( rst_ni       ),
    .xif_issue_i      ( xif_issue_i  ),
    .xif_commit_i     ( xif_commit_i ),
    .id2ex_o          ( id2ex        ),
    .id2ctrl_o        ( id2ctrl      ),
    .ctrl2id_i        ( ctrl2id      )
  )

  fir_xifu_ex i_ex (
    .clk_i            ( clk_i        ),
    .rst_ni           ( rst_ni       ),
    .xif_mem_o        ( xif_mem_o    ),
    .id2ex_i          ( id2ex        ),
    .ex2wb_o          ( ex2wb        ),
    .ex2ctrl_o        ( ex2ctrl      ),
    .ctrl2ex_i        ( ctrl2ex      )
  )

  fir_xifu_wb i_wb (
    .clk_i            ( clk_i            ),
    .rst_ni           ( rst_ni           ),
    .xif_mem_result_i ( xif_mem_result_i ),
    .xif_result_o     ( xif_result_o     ),
    .ex2wb_i          ( ex2wb            ),
    .wb2ctrl_o        ( wb2ctrl          ),
    .ctrl2wb_i        ( ctrl2wb          )
  )
  
  fir_xifu_ctrl i_ctrl (
    .clk_i            ( clk_i   ),
    .rst_ni           ( rst_ni  ),
    .id2ctrl_i        ( id2ctrl ),
    .ctrl2id_o        ( ctrl2id ),
    .ex2ctrl_i        ( ex2ctrl ),
    .ctrl2ex_o        ( ctrl2ex ),
    .wb2ctrl_i        ( wb2ctrl ),
    .ctrl2wb_o        ( ctrl2wb )
  )
  
endmodule /* fir_xifu_top */
