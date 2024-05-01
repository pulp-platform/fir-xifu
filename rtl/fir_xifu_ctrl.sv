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
  import fir_xifu_pkg::*; 
#(
  parameter int unsigned NB_REGS = 4
)
(
  input  logic clk_i,
  input  logic rst_ni,

  input  fir_xifu_id2ctrl_t id2ctrl_i,
  output fir_xifu_ctrl2id_t ctrl2id_o,
  input  fir_xifu_ex2ctrl_t ex2ctrl_i,
  output fir_xifu_ctrl2ex_t ctrl2ex_o,
  input  fir_xifu_wb2ctrl_t wb2ctrl_i,
  output fir_xifu_ctrl2wb_t ctrl2wb_o
);

  localparam int unsigned TAPS_PER_WORD = 32 / DATA_WIDTH;
  
  logic [NB_REGS-1:0][31:0] regs_d, regs_q;

  // EX/WB pipe stage
  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      regs_q <= '0;
    end
    else if (xif_issue_i.issue_valid) begin
      ex2wb_o.next_addr <= next_addr;
      ex2wb_o.register  <= xifu_get_rs1(xif_issue_i.instr);
    end
  end

`ifndef SYNTHESIS
`ifndef VERILATOR
  // use assertions to check that the streams have the correct width
  // assert property (@(posedge clk_i) disable iff(~rst_ni)
  //   (h_parallel.DATA_WIDTH) == (DATA_WIDTH*NB_TAPS));
  // assert property (@(posedge clk_i) disable iff(~rst_ni)
  //   (h_serial.DATA_WIDTH) == (DATA_WIDTH));
  assert property (@(posedge clk_i) disable iff(~rst_ni)
    (32/TAPS_PER_WORD) == (DATA_WIDTH));
`endif
`endif

endmodule /* fir_xifu_ctrl */
