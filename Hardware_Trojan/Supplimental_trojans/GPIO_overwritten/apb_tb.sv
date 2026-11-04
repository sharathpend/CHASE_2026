`timescale 1ns / 1ps

module tb_apb_gpio();

    // Testbench Signals
    reg         HCLK;
    reg         HRESETn;
    reg  [11:0] PADDR;
    reg  [31:0] PWDATA;
    reg         PWRITE;
    reg         PSEL;
    reg         PENABLE;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;
    reg  [31:0] gpio_in;
    wire [31:0] gpio_in_sync;
    wire [31:0] gpio_out;
    wire [31:0] gpio_dir;
    wire [31:0][5:0] gpio_padcfg;
    wire        interrupt;
    reg         dft_cg_enable_i; // DFT clock gating enable signal

    // Instantiate the Unit Under Test (UUT)
    apb_gpio uut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .gpio_in(gpio_in),
        .gpio_in_sync(gpio_in_sync),
        .gpio_out(gpio_out),
        .gpio_dir(gpio_dir),
        .gpio_padcfg(gpio_padcfg),
        .interrupt(interrupt),
        .dft_cg_enable_i(dft_cg_enable_i)
    );

    // Clock generation
    always #5 HCLK = ~HCLK;  // Generate a clock with 10ns period (100MHz)

    // Initial Setup and Reset
    initial begin
        // Initialize Inputs
        HCLK = 0;
        HRESETn = 0;
        PADDR = 0;
        PWDATA = 0;
        PWRITE = 0;
        PSEL = 0;
        PENABLE = 0;
        gpio_in = 0;
        dft_cg_enable_i = 0;  // Start with DFT clock gating disabled

        // Reset the system
        #15;
        HRESETn = 1;  // Release reset
        #10;

        // Begin testing
        test_lock_register();
        test_dft_mode();
        #100;
        $finish;
    end

    // Test the lock register functionality
    task test_lock_register;
        begin
            // Set lock register (attempt to lock)
            write_apb(`REG_GPIOLOCK, 32'hFFFFFFFF);
            #20;

            // Attempt to overwrite lock register (should not change if properly locked)
            write_apb(`REG_GPIOLOCK, 32'h00000000);
            #20;

            // Read back lock register
            read_apb(`REG_GPIOLOCK);
            #20;

            if (PRDATA !== 32'hFFFFFFFF) begin
                $display("Test Failed: Lock register was overwritten.");
            end else begin
                $display("Test Passed: Lock register is secure.");
            end
        end
    endtask

    // Test the effect of DFT clock gating mode
    task test_dft_mode;
        begin
            // Enable DFT mode (disabling clock gating)
            dft_cg_enable_i = 1;
            #10;

            // Execute specific tests with DFT mode enabled
            write_apb(`REG_PADOUT, 32'hAAAA5555);
            read_apb(`REG_PADOUT);
            #10;

            if (PRDATA !== 32'hAAAA5555) begin
                $display("Test Failed: Output register write failed in DFT mode.");
            end else begin
                $display("Test Passed: DFT mode allows normal operations.");
            end

            // Disable DFT mode (enabling clock gating)
            dft_cg_enable_i = 0;
            #10;
        end
    endtask

    // APB Write
    task write_apb(input [11:0] addr, input [31:0] data);
        begin
            PADDR <= addr;
            PWDATA <= data;
            PWRITE <= 1'b1;
            PSEL <= 1'b1;
            PENABLE <= 1'b0; // Start the transaction
            #10; // Wait half a cycle
            PENABLE <= 1'b1; // Enable high to latch the write
            #10;
            PSEL <= 1'b0; // Deselect the peripheral
            PENABLE <= 1'b0; // End the transaction
            #10; // Wait for effects
        end
    endtask

    // APB Read
    task read_apb(input [11:0] addr);
        begin
            PADDR <= addr;
            PWRITE <= 1'b0;
            PSEL <= 1'b1;
            PENABLE <= 1'b0; // Start the transaction
            #10; // Wait half a cycle
            PENABLE <= 1'b1; // Enable high to latch the read
            #10;
            PSEL <= 1'b0; // Deselect the peripheral
            PENABLE <= 1'b0; // End the transaction
            #10; // Wait for effects
        end
    endtask

endmodule
