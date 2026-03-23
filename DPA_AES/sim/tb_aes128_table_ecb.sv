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

  localparam MAX_NUM_TESTS = 5000; // don't change
  localparam NUM_TESTS_TO_RUN = 5000;
  localparam SECRET_KEY = 128'h000102030405060708090A0B0C0D0E0F;

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
  wire [127:0] text_out_tb_sig;      // Out - Cipher Text or Inverse Cipher Text output
  wire         busy_tb_sig;          // Out - AES unit Busy


  reg [127:0] expected_ciphertext_tb_sig = 'h0;
  reg [127:0] ciphertext_out_tb_sig = 'h0;

  // Watchdog timeout
  reg [WD_TIMER_SIZE-1:0] wd_timer_tb_sig = {WD_TIMER_SIZE{1'd1}};
  reg timeout_error_tb_sig = 'b0;

  reg [31:0] cur_test_num_tb_sig = 'd0;

  reg [AES_SIZE+AES_SIZE-1:0] test_vectors_tb_sig [0:MAX_NUM_TESTS-1]; // contains inputs a and b.

  string vcd_filename;

  // VCD registers to figure out test number and whether test us running or not.
  reg [31:0] test_num_tb_sig = 'd0;
  reg test_running_tb_sig = 'b0;


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
    .text_out (text_out_tb_sig), // Out - Cipher Text or Inverse Cipher Text output
    //.busy_reg (busy_tb_sig)          // Out - AES unit Busy
    .busy (busy_tb_sig)          // Out - AES unit Busy
  );


  // Task to initialize, read any files if needed
  task t_initialize_test; begin
    $display("");
    $timeformat(-9, 3, "ns", 6); // -9 = ns. 3 = 3 places after decimal.
    //$dumpfile("wave_full.vcd");
    //$dumpvars(0, tb_aes128_table_ecb);

    $readmemh("/content/SATC_EDU/sim/plaintext_ciphertext_orig_5000.txt", test_vectors_tb_sig);
    //$readmemh("plaintext_ciphertext.txt", test_vectors_tb_sig);
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
    text_in_tb_sig <= test_vectors_tb_sig[cur_test_num_tb_sig][255:128];
    expected_ciphertext_tb_sig <= test_vectors_tb_sig[cur_test_num_tb_sig][127:0];
    $display("");
    $display("[T=%0t] Info: Running Test Number %0d", $realtime, (cur_test_num_tb_sig+1));
    $display("[T=%0t] Info: Input Plaintext     = %32h", $realtime, test_vectors_tb_sig[cur_test_num_tb_sig][255:128]);
    $display("[T=%0t] Info: Expected Ciphertext = %32h", $realtime, test_vectors_tb_sig[cur_test_num_tb_sig][127:0]);
    cur_test_num_tb_sig <= cur_test_num_tb_sig + 'b1;
  end
  endtask

  // Check if output matches expected result
  task t_check_test_result; begin
    $display("[T=%0t] Info: Output Ciphertext   = %32h", $realtime, ciphertext_out_tb_sig);
    if (ciphertext_out_tb_sig == expected_ciphertext_tb_sig) begin
      $display("[T=%0t] Info: Test Pass", $realtime);
    end else begin
      $display("[T=%0t] Error: Test Fail", $realtime);
    end
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
    t_n_cycle_delay('d1);
    t_check_test_result();
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

    // TB regs for post processing script to split up tests
    $dumpvars(0, tb_aes128_table_ecb.test_num_tb_sig);
    $dumpvars(0, tb_aes128_table_ecb.test_running_tb_sig);

    // Registers in TB that would have been in the DUT in an implementation
    $dumpvars(0, tb_aes128_table_ecb.clk_reg);
    $dumpvars(0, tb_aes128_table_ecb.rst_n_reg);

    // All vars in DUT recursively
    $dumpvars(0, tb_aes128_table_ecb.dut);
    //$dumpvars(0, tb_aes128_table_ecb.dut.state_reg_0);
    //$dumpvars(0, tb_aes128_table_ecb.dut.state_reg_1);
    //$dumpvars(0, tb_aes128_table_ecb.dut.state_reg_2);
    //$dumpvars(0, tb_aes128_table_ecb.dut.state_reg_3);

    /*
    // TB regs for post processing script to split up tests
    $dumpvars(0, tb_aes128_table_ecb.test_num_tb_sig);
    $dumpvars(0, tb_aes128_table_ecb.test_running_tb_sig);

    // Registers in TB that would have been in the DUT in an implementation
    $dumpvars(0, tb_aes128_table_ecb.clk_reg);
    $dumpvars(0, tb_aes128_table_ecb.rst_n_reg);

    // Registers in DUT
    $dumpvars(0, tb_aes128_table_ecb.dut.key_val_tb_sig);
    $dumpvars(0, tb_aes128_table_ecb.dut.text_val_tb_sig);
    $dumpvars(0, tb_aes128_table_ecb.dut.busy_tb_sig);
    $dumpvars(0, tb_aes128_table_ecb.dut.now_state);
    $dumpvars(0, tb_aes128_table_ecb.dut.next_state);
    $dumpvars(0, tb_aes128_table_ecb.dut.start_flag);
    $dumpvars(0, tb_aes128_table_ecb.dut.round_n);
    $dumpvars(0, tb_aes128_table_ecb.dut.w[0]);
    $dumpvars(0, tb_aes128_table_ecb.dut.w[1]);
    $dumpvars(0, tb_aes128_table_ecb.dut.w[2]);
    $dumpvars(0, tb_aes128_table_ecb.dut.w[3]);
    $dumpvars(0, tb_aes128_table_ecb.dut.round10_key);
    $dumpvars(0, tb_aes128_table_ecb.dut.iw[0]);
    $dumpvars(0, tb_aes128_table_ecb.dut.iw[1]);
    $dumpvars(0, tb_aes128_table_ecb.dut.iw[2]);
    $dumpvars(0, tb_aes128_table_ecb.dut.iw[3]);
    $dumpvars(0, tb_aes128_table_ecb.dut.state[0]);
    $dumpvars(0, tb_aes128_table_ecb.dut.state[1]);
    $dumpvars(0, tb_aes128_table_ecb.dut.state[2]);
    $dumpvars(0, tb_aes128_table_ecb.dut.state[3]);
    $dumpvars(0, tb_aes128_table_ecb.dut.istate[0]);
    $dumpvars(0, tb_aes128_table_ecb.dut.istate[1]);
    $dumpvars(0, tb_aes128_table_ecb.dut.istate[2]);
    $dumpvars(0, tb_aes128_table_ecb.dut.istate[3]);
    $dumpvars(0, tb_aes128_table_ecb.dut.istate);
    */

    $dumpoff;
  end
  endtask

  // Run mutiple number of enc tests with reset between the tests.
  task t_run_enc_test_multi_with_rst (input [31:0] num); begin
    t_start_vcd_dump();

    repeat(num) begin
      t_assert_dut_rst();
      
      $dumpon;
      t_n_cycle_delay('d1);
      test_num_tb_sig <= test_num_tb_sig + 'd1;
      test_running_tb_sig <= 'b1;
      t_n_cycle_delay('d1);
      
      t_run_test_single('d0);
      
      test_running_tb_sig <= 'b0;
      t_n_cycle_delay('d2);
      $dumpoff;
    end
  end
  endtask


  initial begin
    t_initialize_test();
    t_clear_inputs();
    t_assert_dut_rst();

    t_run_enc_test_multi_with_rst(NUM_TESTS_TO_RUN);

    $display("");
    $display("");
    t_n_cycle_delay('d100);
    $finish;
  end

  always begin
    #CLK_HALF_PERIOD;
    clk_reg = ~clk_reg;
  end

endmodule
