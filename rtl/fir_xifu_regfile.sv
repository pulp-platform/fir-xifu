/*
 * fir_xifu_regfile.sv
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

module fir_xifu_regfile 
  import fir_xifu_pkg::*; 
#(
  parameter int unsigned NB_REGS = 4
)
(
  input  logic clk_i,
  input  logic rst_ni,

  input  fir_xifu_ex2regfile_t ex2regfile_i,
  output fir_xifu_regfile2ex_t regfile2ex_o,
  input  fir_xifu_wb2regfile_t wb2regfile_i
);
  
  logic [NB_REGS-1:0][31:0] regs_q;
  
  // 3 RF read ports in EX stage (three MUX networks)
  assign regfile2ex_o.op_a = regs_q[ex2regfile_i.rs1];
  assign regfile2ex_o.op_b = regs_q[ex2regfile_i.rs2];
  assign regfile2ex_o.op_c = regs_q[ex2regfile_i.rd];

  // 1 RF write port in WB stage
  for(genvar ii=0; ii<NB_REGS; ii++) begin

    // the separate write_en allow for separate automatic clock-gating of the RF
    logic write_en;
    assign write_en = wb2regfile_i.write & (wb2regfile_i.rd == ii);

    always_ff @(posedge clk_i or negedge rst_ni)
    begin
      if(~rst_ni) begin
        regs_q[ii] <= '0;
      end 
      else if(write_en)
        regs_q[ii] <= wb2regfile_i.result;
      end
    end

  end

endmodule /* fir_xifu_regfile */
