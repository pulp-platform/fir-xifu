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
  input  logic clear_i,

  cv32e40x_if_xif.coproc_issue xif_issue_i,
  
  output id2ex_t   id2ex_o,

  output id2ctrl_t id2ctrl_o,

  input  logic ready_i
);

  // Back-prop ready: if the EX stage is ready to accept a new instruction,
  // then the XIFU can accept a new instruction to be issued/decoded.
  assign xif_issue_i.issue_ready = ready_i;

  // Decode XIFU-supported instructions: in this example, we support three
  // different instructions:
  //  - `xfirlw xrd, Imm(rs1)` is an I-format instruction moving a word from
  //    the address given by a base stored in the `rs1` register (in the 
  //    core reg. file) into the XIFU register `xrd`; this instruction also
  //    auto-increments `rs1` by the offset `Imm`.
  //  - `xfirsw Imm(rs1), xrs2` is an S-format instruction right-shifting
  //    a word from the XIFU register `xrs2` by `Imm[4:0]` (5 LSB of the
  //    immediate) and moving it into the address given by a base stored in
  //    the `rs1` register (in the core reg. file); this instruction also
  //    auto-increments `rs1` by the offset `Imm[11:5]` (7 MSB of the
  //    immediate).
  //  - `xfirdotp xrd, xrs1, xrs2` is an R-format instruction taking two words
  //    from the `xrs1`, `xrs2` XIFU registers and performing the dot-product
  //    between them considering them as int16 data vectors, and adding this
  //    to the value stored in `xrd`. The result is stored in `xrd` in int32
  //    format.
  // The following procedural block responds to the XIF issue request by
  //  1) decoding the instruction and ascertaining if it is supported or not;
  //     in that case, it is not accepted and the core raises an illegal
  //     instruction exception;
  //  2) reporting back whether the instruction is a load/store, whether it
  //     writes back to a core register, and other info (e.g., whether it
  //     can raise an exception), which here are omitted for simplicity.
  logic valid_instr;
  instr_t instr;
  always_comb
  begin
    xif_issue_i.issue_resp = '0;
    valid_instr = 1'b0;
    instr = INSTR_INVALID;
    if(xif_issue_i.issue_valid & (xifu_get_opcode(xif_issue_i.issue_req.instr) == INSTR_OPCODE)) begin
      unique case(xifu_get_funct3(xif_issue_i.issue_req.instr))
        INSTR_XFIRLW_FUNCT3 : begin
          xif_issue_i.issue_resp.accept = 1'b1;
          xif_issue_i.issue_resp.writeback = 1'b1;
          xif_issue_i.issue_resp.loadstore = 1'b1;
          valid_instr = 1'b1;
          instr = INSTR_XFIRLW;
        end
        INSTR_XFIRSW_FUNCT3 : begin
          xif_issue_i.issue_resp.accept = 1'b1;
          xif_issue_i.issue_resp.writeback = 1'b1;
          xif_issue_i.issue_resp.loadstore = 1'b1;
          valid_instr = 1'b1;
          instr = INSTR_XFIRSW;
        end
        INSTR_XFIRDOTP_FUNCT3 : begin
          xif_issue_i.issue_resp.accept = 1'b1;
          xif_issue_i.issue_resp.writeback = 1'b0;
          xif_issue_i.issue_resp.loadstore = 1'b0;
          valid_instr = 1'b1;
          instr = INSTR_XFIRDOTP;
        end
        default : begin
          xif_issue_i.issue_resp = '0;
          valid_instr = 1'b0;
          instr = INSTR_INVALID;
        end
      endcase
    end
  end

  // Save issue state in controller scoreboard: the XIFU needs to
  // keep track of instructions issued and retired as the core needs
  // to commit them via the XIF commit interface before they change the
  // architectural state. The controller contains a small scoreboard
  // designed for this purpose.
  assign id2ctrl_o.issue = valid_instr;
  assign id2ctrl_o.id    = xif_issue_i.issue_req.id;

  // ID/EX pipe stage: all the instruction information is saved and
  // passed along the pipeline. Contrarily to the CV32E40X pipeline, which
  // uses a valid/ready handshake, in this case we use only a ready signal.
  id2ex_t id2ex_d;
  always_comb
  begin
    id2ex_d = '0;
    if(instr != INSTR_INVALID) begin
      id2ex_d.base = xif_issue_i.issue_req.rs[0];
      if(instr == INSTR_XFIRSW) begin
        id2ex_d.offset <= xifu_get_immediate_S(xif_issue_i.issue_req.instr)[11:5] * 32'sh1; // * 32'sh1 == sign-extend
      end
      else begin
        id2ex_d.offset <= xifu_get_immediate_I(xif_issue_i.issue_req.instr);
      end
      id2ex_d.instr = instr;
      id2ex_d.rs1 = xifu_get_rs1(xif_issue_i.issue_req.instr);
      id2ex_d.rs2 = xifu_get_rs2(xif_issue_i.issue_req.instr);
      id2ex_d.rd  = xifu_get_rd(xif_issue_i.issue_req.instr);
      id2ex_d.id  = xif_issue_i.issue_req.id;
    end
  end
  
  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      id2ex_o <= '0;
    end
    else if(clear_i) begin
      id2ex_o <= '0;
    end
    else if (ready_i) begin
      id2ex_o <= id2ex_d;
    end
  end

endmodule /* fir_xifu_id */
