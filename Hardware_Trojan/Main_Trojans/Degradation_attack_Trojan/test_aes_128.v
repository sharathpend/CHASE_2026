/*
 * Copyright 2012, Homer Hsing <homer.hsing@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`timescale 1ns / 1ps

module test_aes_128;

    // Inputs
    reg          clk;
    reg  [127:0] state;
    reg  [127:0] key;

    // Output
    wire [127:0] out;

    // Unit under test
    aes_128 uut (
        .clk  (clk),
        .state(state),
        .key  (key),
        .out  (out)
    );

    // 10 ns clock
    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        state = 0;
        key   = 0;

        // Waveform dump. Depth 2 records the testbench signals and the signals
        // declared directly inside aes_128. Use $dumpvars(0, test_aes_128) to
        // record every submodule as well.
        $dumpfile("wave.vcd");
        $dumpvars(2, test_aes_128);

        #100;
        @(negedge clk);

        // Key
        key = 128'h000102030405060708090A0B0C0D0E0F;

        // Five plaintexts, one per clock cycle
        state = 128'h35AA_E73F_0C51_EF86_9F20_2A53_C6FA_53AC;
        #10;
        state = 128'hDF88_D275_A4A6_147D_A5E8_2758_4FE7_A2AA;
        #10;
        state = 128'h80CC_46DA_CA2D_B42E_FA59_ADCA_A8EF_FE1D;
        #10;
        state = 128'hDE49_E57D_F88A_4FDA_904D_F9E6_835B_AA5B;
        #10;
        state = 128'hA708_0259_E334_DB17_03D1_23AF_85DC_13E7;
        #10;

        // Wait for the last result to leave the pipeline, then stop
        #300;
        $display("[%0d ns] Simulation finished.", $time);
        $finish;
    end
endmodule
