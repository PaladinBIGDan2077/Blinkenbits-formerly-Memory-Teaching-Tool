module multiplexer_1bit(
    input        clock_50,
    input        clock_in,
    input        advance_in,
    input        switch,
    input        reset_active_low,
    output logic sys_clock
    );
    
    logic   clock_toggle;
    
    always_ff @(negedge clock_50, negedge reset_active_low) begin
        if (!reset_active_low) begin
            clock_toggle <= 1'b0;
        end
        else begin
            if (switch) begin
                clock_toggle <= 1'b1;
            end
            else begin
                clock_toggle <= 1'b0;
            end
        end
    end
    
    always_comb begin
        if (clock_toggle) begin
            sys_clock = clock_in;
        end
        else if (!clock_toggle) begin
            sys_clock = advance_in;
        end
        else begin
            sys_clock = 1'b0;
        end
    end
    
endmodule