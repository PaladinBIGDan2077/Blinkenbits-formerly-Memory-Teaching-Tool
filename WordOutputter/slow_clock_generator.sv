module slow_clock_generator(
    input                               clock,
    input                               reset_active_low,
    output              logic                slow_clock
);

    // 50,000,000 Hz / 0.5 Hz = 100,000,000 cycles per full period
    // Toggling the output every half-period requires counting to
    // (100,000,000 / 2) - 1 = 50,000,000
    localparam int unsigned HALF_PERIOD_COUNT = 32'd49_999_999;

    logic [25:0] counter;  // 25 bits covers up to ~33.5M

    always_ff @(posedge clock or negedge reset_active_low) begin
        if (!reset_active_low) begin
            counter <= '0;
            slow_clock <= 1'b0;
        end else begin
            if (counter == HALF_PERIOD_COUNT) begin
                counter <= '0;
                slow_clock <= ~slow_clock;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
endmodule
