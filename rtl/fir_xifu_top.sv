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
 * The FIR eXtension Interface Functional Unit (XIFU) is an example coprocessor
 * for teaching purposes using the CV-XIF interface, meant to be connected
 * primarily to CV32E40X.
 * It is organized in a "parallel" pipeline with ID, EX, WB stages (IF is missing
 * because the CV32E40X core does not currently support compressed XIF
 * instructions), plus a register file and a simple controller with a small
 * instruction scoreboard.
 */

module fir_xifu_top
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*;
#(
  parameter int unsigned NB_REGS = 4
)
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

  logic clear;

  ex2regfile_t ex2regfile;
  regfile2ex_t regfile2ex;
  wb2regfile_t wb2regfile;

  id2ex_t id2ex;
  ex2wb_t ex2wb;

  id2ctrl_t id2ctrl;
  ctrl2ex_t ctrl2ex;
  wb2ctrl_t wb2ctrl;
  ctrl2wb_t ctrl2wb;

  wb_fwd_t wb_fwd;

  logic wb_ready, ex_ready;

  // CV32E40X does not currently support compressed XIF instructions
  assign xif_compressed_i.compressed_ready = 1'b1;
  assign xif_compressed_i.compressed_resp  = '0;

  fir_xifu_id i_id (
    .clk_i            ( clk_i       ),
    .rst_ni           ( rst_ni      ),
    .clear_i          ( clear       ),
    .xif_issue_i      ( xif_issue_i ),
    .id2ex_o          ( id2ex       ),
    .wb_fwd_i         ( wb_fwd      ),
    .id2ctrl_o        ( id2ctrl     ),
    .ready_i          ( ex_ready    )
  );

  fir_xifu_ex i_ex (
    .clk_i            ( clk_i      ),
    .rst_ni           ( rst_ni     ),
    .clear_i          ( clear      ),
    .xif_mem_o        ( xif_mem_o  ),
    .id2ex_i          ( id2ex      ),
    .ex2wb_o          ( ex2wb      ),
    .ex2regfile_o     ( ex2regfile ),
    .regfile2ex_i     ( regfile2ex ),
    .ctrl2ex_i        ( ctrl2ex    ),
    .wb_fwd_i         ( wb_fwd     ),
    .ready_o          ( ex_ready   ),
    .ready_i          ( wb_ready   )
  );

  fir_xifu_wb i_wb (
    .clk_i            ( clk_i            ),
    .rst_ni           ( rst_ni           ),
    .xif_mem_result_i ( xif_mem_result_i ),
    .xif_result_o     ( xif_result_o     ),
    .ex2wb_i          ( ex2wb            ),
    .wb2regfile_o     ( wb2regfile       ),
    .wb2ctrl_o        ( wb2ctrl          ),
    .ctrl2wb_i        ( ctrl2wb          ),
    .wb_fwd_o         ( wb_fwd           ),
    .ready_o          ( wb_ready         ),
    .kill_o           ( clear            )
  );

  fir_xifu_ctrl i_ctrl (
    .clk_i            ( clk_i        ),
    .rst_ni           ( rst_ni       ),
    .xif_commit_i     ( xif_commit_i ),
    .id2ctrl_i        ( id2ctrl      ),
    .ctrl2ex_o        ( ctrl2ex      ),
    .wb2ctrl_i        ( wb2ctrl      ),
    .ctrl2wb_o        ( ctrl2wb      )
  );
  
  fir_xifu_regfile #(
    .NB_REGS ( NB_REGS )
  )i_regfile (
    .clk_i            ( clk_i      ),
    .rst_ni           ( rst_ni     ),
    .ex2regfile_i     ( ex2regfile ),
    .regfile2ex_o     ( regfile2ex ),
    .wb2regfile_i     ( wb2regfile )
  );
  
endmodule /* fir_xifu_top */
