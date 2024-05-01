/*
 * fir_xifu_id.sv
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

module fir_xifu_id
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*;
(
  input  logic clk_i,
  input  logic rst_ni,

  cv32e40x_if_xif.coproc_issue xif_issue_i,
  
  output fir_xifu_id2ex_t   id2ex_o,

  output fir_xifu_id2ctrl_t id2ctrl_o,
  input  fir_xifu_ctrl2id_t ctrl2id_i
);

  // the XIFU is always ready to accept instructions
  assign xif_issue_i.issue_ready = 1'b1;

  // decode XIFU-supported instructions
  logic valid_instr;
  logic store;

  always_comb
  begin
    xif_issue_i.issue_resp = '0;
    valid_instr = 1'b0;
    store = 1'b0;
    if(xif_issue_i.issue_valid & (xifu_get_opcode(xif_issue_i.issue_req.instr) == INSTR_OPCODE)) begin
      unique case(xifu_get_funct3(xif_issue_i.issue_req.instr))
        INSTR_LDTAP_FUNCT3 : begin
          xif_issue_i.issue_resp.accept = 1'b1;
          xif_issue_i.issue_resp.writeback = 1'b1;
          xif_issue_i.issue_resp.loadstore = 1'b1;
          valid_instr = 1'b1;
          store = 1'b0;
        end
        INSTR_LDSAM_FUNCT3 : begin
          xif_issue_i.issue_resp.accept = 1'b1;
          xif_issue_i.issue_resp.writeback = 1'b1;
          xif_issue_i.issue_resp.loadstore = 1'b1;
          valid_instr = 1'b1;
          store = 1'b0;
        end
        INSTR_STSAM_FUNCT3 : begin
          xif_issue_i.issue_resp.accept = 1'b1;
          xif_issue_i.issue_resp.writeback = 1'b1;
          xif_issue_i.issue_resp.loadstore = 1'b1;
          valid_instr = 1'b1;
          store = 1'b1;
        end
        default : begin
          xif_issue_i.issue_resp = '0;
          valid_instr = 1'b0;
          store = 1'b0;
        end
      endcase
    end
  end

  // ID/EX pipe stage
  fir_xifu_id2ex_t id2ex_d;

  always_comb
  begin
    id2ex_d = '0;
    id2ex_d.base = xif_issue_i.issue_req.rs[0];
    if(store) begin
      id2ex_d.offset <= xifu_get_immediate_S(xif_issue_i.issue_req.instr);
    end
    else begin
      id2ex_d.offset <= xifu_get_immediate_I(xif_issue_i.issue_req.instr);
    end
    id2ex_d.store = store;
    id2ex_d.rs1 = xifu_get_rs1(xif_issue_req.instr);
    id2ex_d.rd  = xifu_get_rd(xif_issue_req.instr);
  end
  
  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      id2ex_o <= '0;
    end
    else if (xif_issue_i.issue_valid & valid_instr) begin
      id2ex_o <= id2ex_d;
    end
  end

  // to CTRL / XIFU reg file
  always_comb
  begin
    id2ctrl_o = '0;
    id2ctrl_o.rs1 = xifu_get_rs1(xif_issue_req.instr);
    id2ctrl_o.rs2 = xifu_get_rs2(xif_issue_req.instr);
    id2ctrl_o.rd  = xifu_get_rd(xif_issue_req.instr);
  end

endmodule /* fir_xifu_id */
