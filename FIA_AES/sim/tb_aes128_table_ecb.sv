`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2025 03:25:22 PM
// Design Name: 
// Module Name: tb_aes128_table_ecb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module tb_aes128_table_ecb;
  

  // Clock/delay parameters
  localparam CLK_PERIOD = 10;
  localparam CLK_HALF_PERIOD = CLK_PERIOD / 2;
  localparam RUN_TEST_DELAY = 1; // unused

  localparam MAX_NUM_TESTS = 1; // don't change
  localparam NUM_TESTS_TO_RUN = 1;
  //localparam SECRET_KEY = 128'h00112233445566778899AABBCCDDEEFF;
  localparam SECRET_KEY = 128'h000102030405060708090A0B0C0D0E0F;
  localparam STATE_XOR = 128'h10000000000000000000000000000000;

  localparam WD_TIMER_SIZE = 5;

  localparam AES_SIZE=128;
  
  reg  clk_reg = 'd0;
  reg  rst_n_reg = 'd1;

  reg          enc_dec_tb_sig = 'd0; // In  - Encrypt/Decrypt select. 0:Encrypt  1:Decrypt
  reg          key_exp_tb_sig = 'd0; // In  - Round Key Expansion
  reg          start_tb_sig = 'd0;   // In  - Encrypt or Decrypt Start
  wire         key_val_tb_sig;       // Out - Round Key valid
  wire         text_val_tb_sig;      // Out - Cipher Text or Inverse Cipher Text valid
  reg  [127:0] key_in_tb_sig = 'd0;  // In  - Key input
  reg  [127:0] text_in_tb_sig = 'd0; // In  - Cipher Text or Inverse Cipher Text input
  reg  [127:0] state_xor_in_sig [0:0]; // In  - Cipher Text or Inverse Cipher Text input
  wire [127:0] text_out_tb_sig;      // Out - Cipher Text or Inverse Cipher Text output
  wire         busy_tb_sig;          // Out - AES unit Busy


  reg [127:0] expected_ciphertext_tb_sig = 'h0;
  reg [127:0] ciphertext_out_tb_sig = 'h0;

  // Watchdog timeout
  reg [WD_TIMER_SIZE-1:0] wd_timer_tb_sig = {WD_TIMER_SIZE{1'd1}};
  reg timeout_error_tb_sig = 'b0;

  reg [31:0] cur_test_num_tb_sig = 'd0;

  reg [AES_SIZE:0] test_vectors_tb_sig = 128'hDCFEAD50D1D9FD08B386EFB08B142F74;

  string vcd_filename;

  // VCD registers to figure out test number and whether test us running or not.
  reg [31:0] test_num_tb_sig = 'd0;
  reg test_running_tb_sig = 'b0;

  integer f1;


  aes128_table_ecb dut (
    .clock (clk_reg),         // clock.
    .resetn (rst_n_reg),      // Async reset.
    
    .enc_dec (enc_dec_tb_sig),   // In  - Encrypt/Decrypt select. 0:Encrypt  1:Decrypt
    .key_exp (key_exp_tb_sig),   // In  - Round Key Expansion
    .start (start_tb_sig),       // In  - Encrypt or Decrypt Start
    //.key_val_reg (key_val_tb_sig),   // Out - Round Key valid
    .key_val (key_val_tb_sig),   // Out - Round Key valid
    //.text_val_reg (text_val_tb_sig), // Out - Cipher Text or Inverse Cipher Text valid
    .text_val (text_val_tb_sig), // Out - Cipher Text or Inverse Cipher Text valid
    .key_in (key_in_tb_sig),     // In  - Key input
    .text_in (text_in_tb_sig),   // In  - Cipher Text or Inverse Cipher Text input
    .state_xor_in (STATE_XOR), // In - XOR this with current state after round-9 completes.
    .text_out (text_out_tb_sig), // Out - Cipher Text or Inverse Cipher Text output
    //.busy_reg (busy_tb_sig)          // Out - AES unit Busy
    .busy (busy_tb_sig)          // Out - AES unit Busy
  );


  genvar i;
  
  reg [127:0] hw = 'b0;
  wire [9:0] hw_val [127:0];
  
  generate
    for (i = 0; i < 128; i = i + 1) begin
      if (i == 0)
        assign hw_val[i] = text_out_tb_sig[i] + 128'b0;
      else
        assign hw_val[i] = hw_val[i-1] + text_out_tb_sig[i];
    end
  endgenerate
  
  always@ (posedge clk_reg) begin
    if (~rst_n_reg)
      hw <= 'd0;
    else if (text_val_tb_sig)
      hw <= hw_val[127];
  end

  // Task to initialize, read any files if needed
  task t_initialize_test; begin
    $display("");
    $timeformat(-9, 3, "ns", 6); // -9 = ns. 3 = 3 places after decimal.
    //$dumpfile("wave_full.vcd");
    //$dumpvars(0, tb_aes128_table_ecb);

    //$readmemh("/content/SATC_EDU/sim/plaintext_ciphertext_orig_5000.txt", test_vectors_tb_sig);
    state_xor_in_sig[0] <= 'd0;
    //$readmemh("state_xor_input.txt", state_xor_in_sig);
    f1 = $fopen("ciphertext_output.txt", "w");
  end
  endtask
  
  task t_clear_inputs; begin
    clk_reg <= 'b0;
    enc_dec_tb_sig <= 'd0;
    key_exp_tb_sig <= 'd0;
    start_tb_sig <= 'd0;
    key_in_tb_sig <= SECRET_KEY;
    text_in_tb_sig <= 'd0;
    cur_test_num_tb_sig <= 'd0;
    expected_ciphertext_tb_sig <= 'h0;
    ciphertext_out_tb_sig <= 'h0;
    test_num_tb_sig <= 'd0;
    test_running_tb_sig <= 'b0;
    t_wd_timer_clear();
  end
  endtask

  // Task to assert reset
  task t_assert_dut_rst; begin
    rst_n_reg <= 'd1;
    t_n_cycle_delay('d2);
    rst_n_reg <= 'd0;
    t_n_cycle_delay('d5);
    rst_n_reg <= 'd1;
    t_n_cycle_delay('d2);
  end
  endtask
  
  // Task for N cycles of delay
  task t_n_cycle_delay (input [9:0] num); begin
    repeat(num) @(posedge clk_reg);
  end
  endtask

  // Update inputs based on test_vectors_tb_sig
  task t_update_next_test; begin
    text_in_tb_sig <= test_vectors_tb_sig;
    $display("");
    $display("[T=%0t] Info: Running Test Number %0d", $realtime, (cur_test_num_tb_sig+1));
    $display("[T=%0t] Info: Input Plaintext     = %032h", $realtime, test_vectors_tb_sig);
    cur_test_num_tb_sig <= cur_test_num_tb_sig + 'b1;
  end
  endtask



  // Task to set WD Timer to max value
  task t_wd_timer_clear; begin
    wd_timer_tb_sig <= {WD_TIMER_SIZE{1'd1}};
  end
  endtask

  // Task to decrement WD Timer
  task t_wd_timer_dec; begin
    wd_timer_tb_sig <= wd_timer_tb_sig - 'd1;
  end
  endtask

  // Task to check for WB Timeout
  task t_wd_check_timeout; begin
    if (wd_timer_tb_sig == 'd0) begin
      timeout_error_tb_sig <= 'd1;
      $display("[T=%0t] Error: Watchdog Timeout Detected", $realtime);
    end
  end
  endtask

  // Set mode to encryption
  task t_sel_enc; begin
    enc_dec_tb_sig <= 'b0;
  end
  endtask

  // Set mode to decryption
  task t_sel_dec; begin
    enc_dec_tb_sig <= 'b1;
  end
  endtask

  // Run a single test
  task t_run_test_single (input enc_or_dec); begin
    if (enc_or_dec == 'b0) begin
      t_sel_enc();
    end else begin
      t_sel_dec();
    end

    t_update_next_test();

    start_tb_sig <= 'b1;
    t_n_cycle_delay('d1);

    while (key_val_tb_sig == 'b0) begin
      t_n_cycle_delay('d1);
    end
    start_tb_sig <= 'b0;

    while (text_val_tb_sig == 'b0) begin
      t_n_cycle_delay('d1);
    end

    ciphertext_out_tb_sig <= text_out_tb_sig;
    $fwrite(f1, "%032h\n", text_out_tb_sig);
    t_n_cycle_delay('d1);
  end
  endtask

  // Run mutiple number of enc tests
  task t_run_enc_test_multi (input [31:0] num); begin
    repeat(num) t_run_test_single('d0);
  end
  endtask

  // Run mutiple number of dec tests
  task t_run_dec_test_multi (input [31:0] num); begin
    repeat(num) t_run_test_single('d1);
  end
  endtask

  // Dump specific signals for DPA attack
  task t_start_vcd_dump; begin
    vcd_filename = $sformatf("waveform.vcd");
    $dumpfile(vcd_filename);
    $dumpvars(0, tb_aes128_table_ecb);
  end
  endtask

  // Run mutiple number of enc tests with reset between the tests.
  task t_run_enc_test_multi_with_rst (input [31:0] num); begin

    repeat(num) begin
      t_assert_dut_rst();
      
      t_n_cycle_delay('d1);
      test_num_tb_sig <= test_num_tb_sig + 'd1;
      test_running_tb_sig <= 'b1;
      t_n_cycle_delay('d1);
      
      t_run_test_single('d0);
      
      test_running_tb_sig <= 'b0;
      t_n_cycle_delay('d2);
    end
  end
  endtask


  initial begin
    t_initialize_test();
    if (f1 == 0) begin  
      $display("Error: Could not open file for writing.");  
      $finish;  
    end
    t_clear_inputs();
    t_start_vcd_dump();
    t_assert_dut_rst();

    t_run_enc_test_multi_with_rst(NUM_TESTS_TO_RUN);

    $display("");
    $display("");
    t_n_cycle_delay('d100);
    $fclose(f1);
    $finish;
  end

  always begin
    #CLK_HALF_PERIOD;
    clk_reg = ~clk_reg;
  end

endmodule
