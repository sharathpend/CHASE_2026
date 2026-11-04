`timescale 1ns/1ps

module tb_adbg_tap_top;

  reg tck_pad_i = 0;
  reg trstn_pad_i = 0;
  reg tms_pad_i = 0;
  reg tdi_pad_i = 0;
  wire tdo_pad_o;
  wire tdo_padoe_o;
  wire test_logic_reset_o, run_test_idle_o, shift_dr_o, pause_dr_o;
  wire update_dr_o, capture_dr_o;
  wire extest_select_o, sample_preload_select_o, mbist_select_o, debug_select_o;
  wire tdi_o;
  wire debug_tdo_i = 0;
  wire bs_chain_tdo_i = 0;
  wire mbist_tdo_i = 0;

  // Instantiate DUT
  adbg_tap_top dut (
    .tck_pad_i(tck_pad_i),
    .trstn_pad_i(trstn_pad_i),
    .tms_pad_i(tms_pad_i),
    .tdi_pad_i(tdi_pad_i),
    .tdo_pad_o(tdo_pad_o),
    .tdo_padoe_o(tdo_padoe_o),
    .test_mode_i(1'b0),
    .test_logic_reset_o(test_logic_reset_o),
    .run_test_idle_o(run_test_idle_o),
    .shift_dr_o(shift_dr_o),
    .pause_dr_o(pause_dr_o),
    .update_dr_o(update_dr_o),
    .capture_dr_o(capture_dr_o),
    .extest_select_o(extest_select_o),
    .sample_preload_select_o(sample_preload_select_o),
    .mbist_select_o(mbist_select_o),
    .debug_select_o(debug_select_o),
    .tdi_o(tdi_o),
    .debug_tdo_i(debug_tdo_i),
    .bs_chain_tdo_i(bs_chain_tdo_i),
    .mbist_tdo_i(mbist_tdo_i)
  );

  // Clock Generation
  always #5 tck_pad_i = ~tck_pad_i;

  // Apply reset
  initial begin
    trstn_pad_i = 0;
    #20;
    trstn_pad_i = 1;
  end

  // Password Injection Task
  task inject_password(input [30:0] partial_pass, input logic bit_0);
    integer i;
    begin
      // First 31 bits
      for (i = 0; i < 31; i = i + 1) begin
        @(posedge tck_pad_i);
        tdi_pad_i = partial_pass[i];
        tms_pad_i = 0;  // remain in run_test_idle
      end

      // Final bit
      @(posedge tck_pad_i);
      tdi_pad_i = bit_0;
      tms_pad_i = 1;  // try transitioning state (triggers passchk check)
    end
  endtask

  // Main test sequence
  initial begin
    wait(trstn_pad_i);
    @(posedge tck_pad_i);

    // 31 MSBs of 32'hDEADBEEF = 0x6F56DF77
    $display("Injecting 31 correct bits and incorrect final bit (0)");
    inject_password(31'h6F56DF77, 1'b0);
    #10;

    $display("Injecting 31 correct bits and final bit (1)");
    inject_password(31'h6F56DF77, 1'b1);
    #10;

    $finish;
  end

endmodule
