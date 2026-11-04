`timescale 1ns/1ps

module tb_riscv_debug_unit;

  // DUT Inputs
  logic clk;
  logic rst_n;
  logic [15:0] debug_addr_i;
  logic [31:0] debug_data_i;
  logic debug_req_i;
  logic debug_halt_i;

  // DUT Outputs
  logic debug_gnt_o;
  logic [31:0] debug_data_o;
  logic debug_halted_o;
  logic csr_we_o;

  // Internal signal to control halt state
  logic fake_halt;

  // Instantiate DUT
  riscv_debug_unit dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .debug_addr_i(debug_addr_i),
    .debug_data_i(debug_data_i),
    .debug_req_i(debug_req_i),
    .debug_gnt_o(debug_gnt_o),
    .debug_data_o(debug_data_o),
    .debug_halt_i(debug_halt_i),
    .debug_halted_o(debug_halted_o),
    .csr_we_o(csr_we_o)
    // Add other necessary signals depending on your DUT
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    $display("\n--- Starting Trojan Detection Test ---\n");

    // Initialize
    clk = 0;
    rst_n = 0;
    debug_addr_i = 16'h4000;  // Bit 14 = 1 to trigger CSR access
    debug_data_i = 32'hDEADBEEF;
    debug_req_i = 0;
    debug_halt_i = 0;         // Processor not in halt mode
    fake_halt = 0;

    #20 rst_n = 1;

    // Cycle 1: First state (should latch address/data)
    debug_req_i = 1;
    #10;

    // Check during FIRST state
    if (csr_we_o !== 0)
      $display("FAIL: Unexpected CSR write in FIRST state.");

    // Cycle 2: Transition to SECOND state (where Trojan triggers)
    #10;

    // Check if csr_we_o is wrongly enabled
    if (csr_we_o === 1) begin
      $display("TROJAN DETECTED: CSR write enabled while not halted!");
    end else begin
      $display("PASS: CSR write correctly blocked while not halted.");
    end

    $finish;
  end

endmodule
