/*
 * fir_xifu_ctrl.sv
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

module fir_xifu_ctrl
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*; 
(
  input  logic clk_i,
  input  logic rst_ni,

  cv32e40x_if_xif.coproc_commit     xif_commit_i,

  input  id2ctrl_t id2ctrl_i,
  output ctrl2ex_t ctrl2ex_o,
  input  wb2ctrl_t wb2ctrl_i,
  output ctrl2wb_t ctrl2wb_o
);

  // Mask commits that are repeated multiple times for the same ID.
  // The CV-XIF specs actually state that the commit arrives only once,
  // but CV32E40X sometimes generates multiple commits for the same ID.
  logic actual_commit;
  logic                  xif_commit_q;
  logic [X_ID_WIDTH-1:0] xif_id_q;
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni) begin
      xif_commit_q <= '0;
      xif_id_q     <= '0;
    end
    else begin
      xif_commit_q <= xif_commit_i.commit_valid;
      xif_id_q     <= xif_commit_i.commit.id;
    end
  end
  assign actual_commit = (xif_id_q != xif_commit_i.commit.id) ? xif_commit_i.commit_valid : xif_commit_i.commit_valid & ~xif_commit_q;

  // Save issue/commit/kill status in a small scoreboard. Only actually issued instructions can be committed/killed!
  logic [X_ID_MAX-1:0] issue_d, issue_q;
  logic [X_ID_MAX-1:0] valid_d, valid_q;
  logic [X_ID_MAX-1:0] kill_d,  kill_q;
  for(genvar ii=0; ii<X_ID_MAX; ii++) begin
    assign issue_d[ii] = wb2ctrl_i.clear[ii]                             ? 1'b0 :
                         id2ctrl_i.issue && (id2ctrl_i.id == ii)         ? 1'b1 :
                         issue_q[ii];
    assign valid_d[ii] = wb2ctrl_i.clear[ii]                             ? 1'b0 :
                         actual_commit && (xif_commit_i.commit.id == ii) ? issue_q[ii] :
                         valid_q[ii];
    assign kill_d [ii] = wb2ctrl_i.clear[ii]                                                               ? 1'b0 :
                         actual_commit & xif_commit_i.commit.commit_kill && (xif_commit_i.commit.id == ii) ? issue_q[ii] :
                         valid_q[ii];
  end

  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni) begin
      issue_q <= '0;
      valid_q <= '0;
      kill_q  <= '0;
    end
    else begin
      issue_q <= issue_d;
      valid_q <= valid_d;
      kill_q  <= kill_d;
    end
  end

  // commit *must* be registered, as it is used to generate a clear in WB
  assign ctrl2wb_o.issue  = issue_q;
  assign ctrl2wb_o.commit = valid_q;
  assign ctrl2wb_o.kill   = kill_q;

  // commit can be combinational in EX
  // TODO: check whether this is true; according to the architectural diagram
  //       in the XIF specs, commit arrives late in the ID stage, not early in the
  //       EX stage. This might impose a structural hazard in all store ops to
  //       avoid timing issues, which is quite annoying.
  assign ctrl2ex_o.commit = valid_d | valid_q & ~kill_q & ~kill_d;

endmodule /* fir_xifu_ctrl */
