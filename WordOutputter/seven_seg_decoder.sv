module seven_segment_decoder(
    input               logic               [5:0]               data_in,
    output              logic               [6:0]               display_0,
    output              logic               [6:0]               display_1,
    output              logic               [6:0]               display_2,
    output              logic               [6:0]               display_3
);

                        logic               [2:0]               MSB_DATA_OCTAL;
                        logic               [2:0]               LSB_DATA_OCTAL;

    typedef     enum    logic               [6:0]
    {
        LETTER_0_HEX = 7'b1000000,
        LETTER_1_HEX = 7'b1111001,
        LETTER_2_HEX = 7'b0100100,
        LETTER_3_HEX = 7'b0110000,
        LETTER_4_HEX = 7'b0011001,
        LETTER_5_HEX = 7'b0010010,
        LETTER_6_HEX = 7'b0000010,
        LETTER_7_HEX = 7'b1111000,
        LETTER_8_HEX = 7'b0000000,
        LETTER_9_HEX = 7'b0010000,
        LETTER_A_HEX = 7'b0001000,
        LETTER_B_HEX = 7'b0000011,
        LETTER_C_HEX = 7'b1000110,
        LETTER_D_HEX = 7'b0100001,
        LETTER_E_HEX = 7'b0000110,
        LETTER_F_HEX = 7'b0001110,
        DATAVAL_X    = 7'b0110110,
        DATAVAL_O    = 7'b0100011
    }   hex_display;

    always_comb begin
        unique case(LSB_DATA_OCTAL)
            3'o0: display_0 = LETTER_0_HEX;
            3'o1: display_0 = LETTER_1_HEX;
            3'o2: display_0 = LETTER_2_HEX;
            3'o3: display_0 = LETTER_3_HEX;
            3'o4: display_0 = LETTER_4_HEX;
            3'o5: display_0 = LETTER_5_HEX;
            3'o6: display_0 = LETTER_6_HEX;
            3'o7: display_0 = LETTER_7_HEX;
        endcase
    end

    always_comb begin
        unique case(MSB_DATA_OCTAL)
            3'o0: display_1 = LETTER_0_HEX;
            3'o1: display_1 = LETTER_1_HEX;
            3'o2: display_1 = LETTER_2_HEX;
            3'o3: display_1 = LETTER_3_HEX;
            3'o4: display_1 = LETTER_4_HEX;
            3'o5: display_1 = LETTER_5_HEX;
            3'o6: display_1 = LETTER_6_HEX;
            3'o7: display_1 = LETTER_7_HEX;
        endcase
    end

    assign MSB_DATA_OCTAL = data_in[5:3];
    assign LSB_DATA_OCTAL = data_in[2:0];
    assign display_2 = DATAVAL_O;
    assign display_3 = LETTER_0_HEX;

endmodule