module multiplexer_1bit(
    input        clock_in,
    input        advance_in,
    input        switch,
    output logic enable
    );
        
    always_comb begin
        if (switch) begin
            enable = clock_in;
        end
        else begin
            enable = advance_in;
        end
    end
    
endmodule



module multiplexer_6bit_2_to_1(
    input        [5:0] input_a,
    input        [5:0] input_b,
    input        		select,
    output logic [5:0] output_bus
    );
        
    always_comb begin
        if (select) begin
            output_bus = input_a;
        end
        else begin
            output_bus = input_b;
        end
    end
    
endmodule