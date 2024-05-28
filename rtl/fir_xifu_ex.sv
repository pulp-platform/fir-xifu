/*
 * fir_xifu_ex.sv
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

module fir_xifu_ex
  import cv32e40x_pkg::*;
  import fir_xifu_pkg::*; 
(
  input  logic clk_i,
  input  logic rst_ni,
  input  logic clear_i,

  cv32e40x_if_xif.coproc_mem    xif_mem_o,
  
  input  id2ex_t   id2ex_i,
  output ex2wb_t   ex2wb_o,

  output ex2regfile_t ex2regfile_o,
  input  regfile2ex_t regfile2ex_i,

  input  ctrl2ex_t ctrl2ex_i,

  input  wb_fwd_t wb_fwd_i,

  input  logic ready_i,
  output logic ready_o
);

  // Forwarding logic
  logic forwarding;
  assign forwarding = wb_fwd_i.we & (wb_fwd_i.rd == id2ex_i.rs1);

  // Compute addresses: this is used for load/store operations, which
  // need to compute the base+offset (with sign extension for the latter)
  // and also the updated address using postincrement.
  logic [31:0] next_addr, curr_addr; 
  assign curr_addr = ~forwarding ? id2ex_i.base : wb_fwd_i.result;
  assign next_addr = curr_addr; // placeholder: what should be added to this to calculate the real next_addr
                                // i.e., this should be used to implement the address auto-increment
                                // be careful about sign-extensions!

  // Define right-shift amount for stores
  logic [4:0] right_shift;
  assign right_shift = '0; // placeholder: where is the right-shift taken from when it is used? think of
                           // which instruction bits are relevant
  
  // Issue memory transaction (load or store): currently this is issued
  // immediately for loads and only if a commit signal has arrived for
  // stores (typically in the same EX cycle, at least for CV32E40X).
  // The load/store operation is carried out by the core's LSU.
  always_comb
  begin
    xif_mem_o.mem_req   = '0;
    xif_mem_o.mem_valid = '0;
    if(0) begin // placeholder condition: this if should be active with instructions that use
                // CV32E40X's load/store unit
      // placeholder: the mem_req and mem_valid fields should be filled using information from
      //              1) the ID/EX pipe stage, 2) the curr_addr calculated above, 3) one operand
      //              from the register file.
      //              We leave a few hints...
      // keep the next line, but only in case of a store
      xif_mem_o.mem_valid = ctrl2ex_i.commit[id2ex_i.id]; // do not issue memory requests for non-committed store
      // keep the following lines
      xif_mem_o.mem_req.id    = id2ex_i.id;
      xif_mem_o.mem_req.last  = 1'b1;
      xif_mem_o.mem_req.size  = 3'b100;
      xif_mem_o.mem_req.be    = 4'b1111;
      // placeholder: fix the following lines
      xif_mem_o.mem_req.addr  = '0; // what should be the address targeted by the LSU?
      xif_mem_o.mem_req.we    = '0; // when should we issue a store?
      xif_mem_o.mem_req.wdata = '0; // what data should we write back? think of the specifications for the store-type instruction
                                    // Consider that regfile2ex_i.op_a, op_b, op_c correspond to the registers addressed by rs1, rs2, rd
    end
  end

  // Dot product calculation: here we split the operands, extracted from the register
  // file, into 16-bit signed operands and perform the dot-product operation.
  // We use operand gating to (potentially) save a bit of power at the cost of an
  // extra logic layer. Notice the usage of a signed neutral constant (32'sh1) to
  // make sure that the sign-extensions are performed properly.
  logic signed [1:0][15:0] dotp_op_a, dotp_op_b;
  logic signed [1:0][31:0] dotp_prod;
  logic signed [31:0] dotp_op_c, dotp_result;
  // placeholders: connect dotp inputs to operands from register file
  //               remember that regfile2ex_i.op_a/b/c correnspond to rs1/rs2/rd
  assign dotp_op_a = '0; // placeholder: connect dotp inputs to operands from register file
  assign dotp_op_b = '0; // placeholder: connect dotp inputs to operands from register file
  assign dotp_op_c = '0; // placeholder: connect dotp inputs to operands from register file
  // placeholders: construct the products that will sum into a single dot-product. Be extra
  //               careful about sign extension: remember that in SystemVerilog most operations
  //               return unsigned values by default, e.g., if you have
  //                   logic signed [1:0][15:0] foo;
  //               then extracting an element from foo, e.g., foo[0], will return an unsigned
  //               value; also extracting a range, e.g., foo[1:0], will return an unsigned
  //               vector! You need to use explicit castings:
  //                   signed'(foo[0])
  //               Moreover, sign-extension is performed only based on the right-hand
  //               width of an assignment, so if
  //                   logic signed [63:0] long; logic signed [15:0] short_a, short_b;
  //                   assign long = short_a + short_b;
  //               the sign-extensions will NOT be performed. The simplest solution is to use
  //               a neutral element to force sign-extension:
  //                   assign long = 64'sh0 + short_a + short_b
  assign dotp_prod[0] = '0; // placeholder: sum the LSB products from rs1, rs2 
  assign dotp_prod[1] = '0; // placeholder: sum the MSB products from rs1, rs2
  assign dotp_result = '0; // placeholder: sum the products and the incoming accumulator value from rd

  // EX/WB pipe stage
  ex2wb_t ex2wb_d;

  always_comb
  begin
    ex2wb_d = '0;
    ex2wb_d.result = '0; // placeholder: result hosts the result to be written back to a register in
                         //              the XIFU or CV32E40X register file. What should it be, given
                         //              a certain instruction?
    ex2wb_d.rs1    = '0; // placeholder: what should be pass here through the EX/WB pipe stage?
    ex2wb_d.rs2    = '0; // placeholder: what should be pass here through the EX/WB pipe stage?
    ex2wb_d.rd     = '0; // placeholder: what should be pass here through the EX/WB pipe stage?
    ex2wb_d.instr  = '0; // placeholder: what should be pass here through the EX/WB pipe stage?
    ex2wb_d.id     = id2ex_i.id;
  end

  always_ff @(posedge clk_i, negedge rst_ni)
  begin
    if(~rst_ni) begin
      ex2wb_o <= '0;
    end
    else if(clear_i) begin
      ex2wb_o <= '0;
    end
    else if(ready_i) begin
      ex2wb_o <= ex2wb_d;
    end
  end

  // to regfile / XIFU reg file
  always_comb
  begin
    ex2regfile_o = '0;
    ex2regfile_o.rs1 = '0; // placeholder: what should we pass here towards the XIFU regfile?
    ex2regfile_o.rs2 = '0; // placeholder: what should we pass here towards the XIFU regfile?
    ex2regfile_o.rd  = '0; // placeholder: what should we pass here towards the XIFU regfile?
  end

  // backprop ready
  assign ready_o = ready_i;

endmodule /* fir_xifu_ex */
