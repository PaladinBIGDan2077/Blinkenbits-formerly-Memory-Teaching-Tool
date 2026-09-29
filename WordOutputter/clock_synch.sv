module clock_synchronizer
(
	input                                   clock_50,
	input									signal_in, // Clock or button press module
    input                                   reset_active_low,
    output          logic       	        synced_enable
);

	logic			[1:0] 	next_state, state;
	
	parameter 				RISING_EDGE = 2'b00, HOLD = 2'b01, FALLING_EDGE = 2'b10;

	
	always_ff @(posedge clock_50, negedge reset_active_low) begin
		if (!reset_active_low) begin
			state <= RISING_EDGE;
		end
		else begin
			state <= next_state;
		end
	end
	
	always_comb begin
		case(state)
		RISING_EDGE: 		     next_state =	signal_in  ? HOLD : RISING_EDGE;
		HOLD: 					 next_state = 	FALLING_EDGE;
		FALLING_EDGE: 			 next_state =	!signal_in ? RISING_EDGE : FALLING_EDGE;
		default: 	 			 next_state = 	2'bxx;
		endcase
	end

	always_comb begin
		case(state)
		RISING_EDGE:   			 synced_enable = 1'b0;
		HOLD: 		   			 synced_enable = 1'b1;
		FALLING_EDGE:  			 synced_enable = 1'b0;
		endcase
	end

endmodule