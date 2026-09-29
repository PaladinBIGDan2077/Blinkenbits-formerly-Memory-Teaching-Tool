module top_wordoutput(
	input														clock_50,
	input														reset_active_low,
	input														switch,
	input														mode_sel,
	input														advance_in,
	inout			logic										FPGA_I2C_SCLK,
	inout			logic										FPGA_I2C_SDAT,
    output          logic       			[6:0]       		display_0,
    output          logic       			[6:0]       		display_1,
    output          logic       			[6:0]       		display_2,
    output          logic       			[6:0]       		display_3,
	output			logic					[5:0]				addr
	);

                    logic                   					slow_clock;
                    logic                   					enable;
                    logic       			[5:0]       		char_data, word_data, word_char_mux_out;

                    logic                   					char_addr_0;
                    logic                   					char_addr_1;
                    logic                   					char_addr_2;
                    logic                   					char_addr_3;
                    logic                   					char_addr_4;
                    logic                   					char_addr_5;
					
					logic										word_addr_0;
					logic										word_addr_1;
					logic										word_addr_2;
					logic										word_addr_3;
					logic										word_addr_4;
					logic										word_addr_5;
					
					logic										altera_ready;
									
					wire										synched_advanced, synched_slow_clock;

					
					wire 		signed 		[15:0] 				w_fpga_temp;
					wire 		signed 		[15:0] 				w_board_temp;
					wire 		signed 		[15:0] 				w_board2_temp;
					wire        			[15:0] 				w_fan_rpm;
					wire               							w_i2c_ready;
						  

    slow_clock_generator u_slow_clock_generator (
        .clock              (clock_50),
        .reset_active_low   (reset_active_low || altera_ready),
        .slow_clock         (slow_clock)
    );
	
	clock_synchronizer	u_slow_clock_synchronizer (
		.clock_50			(clock_50),
		.signal_in			(slow_clock),
		.reset_active_low	(reset_active_low || altera_ready),
        .synced_enable		(synched_slow_clock)
	);
	
	clock_synchronizer	u_advancer_synchronizer (
		.clock_50			(clock_50),
		.signal_in			(advance_in),
		.reset_active_low	(reset_active_low || altera_ready),
        .synced_enable		(synched_advanced)
	);

    multiplexer_1bit u_multiplexer_1bit (
        .clock_in           (synched_slow_clock),
        .advance_in         (synched_advanced),
        .switch             (switch),
        .enable          	(enable)
    );

    char_decoder u_char_decoder (
        .clock_50           (clock_50),
		.enable				(enable),
        .reset_active_low   (reset_active_low || altera_ready),
        .addr_0             (char_addr_0),
        .addr_1             (char_addr_1),
        .addr_2             (char_addr_2),
        .addr_3             (char_addr_3),
        .addr_4             (char_addr_4),
        .addr_5             (char_addr_5),
        .output_bus         (char_data)
    );
	
    sentence_printer u_word_decoder (
        .clock_50           (clock_50),
		.enable				(enable),
        .reset_active_low   (reset_active_low || altera_ready),
        .addr_0             (word_addr_0),
        .addr_1             (word_addr_1),
        .addr_2             (word_addr_2),
        .addr_3             (word_addr_3),
        .addr_4             (word_addr_4),
        .addr_5             (word_addr_5),
        .output_bus         (word_data)
    );
	
	multiplexer_6bit_2_to_1	u_word_selector_mux
	(
		.input_a			(char_data),
		.input_b        	(word_data),
		.select        		(mode_sel),
		.output_bus			(word_char_mux_out)
    );

    seven_segment_decoder u_seven_segment_decoder (
        .data_in            (word_char_mux_out),
        .display_0          (display_0),
        .display_1          (display_1),
        .display_2          (display_2),
        .display_3          (display_3)
    );
	 
	 FAN_CTRL_FIXED #(
		.TARGET_RPM 		(4000)
	) u_fan_ctrl (
    .clk_50             	(clock_50),
    .reset_n            	(reset_active_low || altera_ready),
    .I2C_SCL            	(FPGA_I2C_SCLK),
    .I2C_SDA            	(FPGA_I2C_SDAT)
	);
	 
	 altera_s10_user_rst_clkgate fpga_ready_reset (
		.ninit_done		    (altera_ready)
	 );
	 
	 assign addr = {word_char_mux_out[5], word_char_mux_out[4], word_char_mux_out[3], word_char_mux_out[2], word_char_mux_out[1], word_char_mux_out[0]};

endmodule