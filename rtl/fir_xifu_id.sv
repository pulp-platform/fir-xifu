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

  cv32e40x_if_xif.coproc_compressed xif_compressed_i,
  
  output fir_xifu_id2ex_t   id2ex_o,

  output fir_xifu_id2ctrl_t id2ctrl_o,
  input  fir_xifu_ctrl2id_t ctrl2id_i
);

  // the XIFU is always ready to accept instructions
  assign xif_compressed_i.compressed_ready = 1'b1;

  // decode XIFU-supported instructions
  always_comb
  begin
    // if(xif_compressed_i.compressed_valid) begin
    //   unique case(xif_compressed_i.compressed_req.instr)
    //     COMPR_INSTR_LDTAP : begin
    //       xif_compressed_i.compressed_resp.accept = 1'b1;
    //       xif_compressed_i.compressed_resp.instr  = INSTR_LDTAP;
    //     end
    //     COMPR_INSTR_LDSAM : begin
    //       xif_compressed_i.compressed_resp.accept = 1'b1;
    //       xif_compressed_i.compressed_resp.instr  = INSTR_LDSAM;
    //     end
    //     COMPR_INSTR_STSAM : begin
    //       xif_compressed_i.compressed_resp.accept = 1'b1;
    //       xif_compressed_i.compressed_resp.instr  = INSTR_STSAM;
    //     end
    //     default : begin
          xif_compressed_i.compressed_resp.accept = '0;
          xif_compressed_i.compressed_resp.instr  = '0;
    //     end
    //   endcase
    // end
  end

  // ID/EX pipe stage (placeholder)
  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      id2ex_o <= '0;
    end
    else if (xif_compressed_i.compressed_valid) begin
      id2ex_o <= '0;
    end
  end

endmodule /* fir_xifu_id */
