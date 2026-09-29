`timescale 1ns/1ns

module tb_wordoutputter;

                    logic                   clock_50;
                    logic                   reset_active_low;
                    logic                   switch;
                    logic                   advance_in;
                    logic       [5:0]       addr;
                    logic       [6:0]       display_0;
                    logic       [6:0]       display_1;
                    logic       [6:0]       display_2;
                    logic       [6:0]       display_3;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    top dut (
        .clock_50           (clock_50),
        .reset_active_low   (reset_active_low),
        .switch             (switch),
        .advance_in         (advance_in),
        .addr               (addr),
        .display_0          (display_0),
        .display_1          (display_1),
        .display_2          (display_2),
        .display_3          (display_3)
    );

    // ------------------------------------------------------------
    // 50 MHz clock: 20 ns period
    // ------------------------------------------------------------
    initial clock_50 = 1'b0;
    always #10 clock_50 = ~clock_50;

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        // Start in reset, manual-advance path selected (switch = 0
        // routes advance_in straight to char_decoder, bypassing the
        // slow_clock_generator so the sim doesn't need ~2 seconds
        // of wall-clock time to see a character change).
        reset_active_low = 1'b0;
        switch            = 1'b0;
        advance_in        = 1'b0;

        repeat (5) @(posedge clock_50);
        reset_active_low = 1'b1;
        @(posedge clock_50);

        // addr/char code should be back at 0 after reset
        if (addr !== 6'd0)
            $error("Reset check failed: addr = %0d, expected 0", addr);
        else
            $display("Reset check passed: addr = %0d", addr);

        // Pulse advance_in a few times and confirm addr increments
        for (int i = 1; i <= 5; i++) begin
            advance_in = 1'b1;   // char_decoder clocks directly off this
            #10;                 // edge when switch = 0
            advance_in = 1'b0;
            #10;

            if (addr !== i)
                $error("Advance check failed at step %0d: addr = %0d, expected %0d", i, addr, i);
            else
                $display("Advance check passed at step %0d: addr = %0d", i, addr);

            $display("  display_0=%b display_1=%b display_2=%b display_3=%b",
                       display_0, display_1, display_2, display_3);
        end

        $display("Testbench complete.");
        $finish;
    end

endmodule