module char_decoder(
    input                                   advance,
    input                                   reset_active_low,
    output          logic                   addr_0,
    output          logic                   addr_1,
    output          logic                   addr_2,
    output          logic                   addr_3,
    output          logic                   addr_4,
    output          logic                   addr_5,
    output          logic       [5:0]       output_bus
);
    localparam              WORD_LENGTH = 28;
    //                        logic             [5:0]                      output_bus;
                            logic             [5:0]                      word_out        [WORD_LENGTH:0];
                            logic             [$clog2(WORD_LENGTH):0]    array_counter;
    
    typedef enum            logic            [5:0]
    {
        SYMBOL_AT  = 6'b000000,
        LETTER_A   = 6'b000001,
        LETTER_B   = 6'b000010,
        LETTER_C   = 6'b000011,
        LETTER_D   = 6'b000100,
        LETTER_E   = 6'b000101,
        LETTER_F   = 6'b000110,
        LETTER_G   = 6'b000111,
        LETTER_H   = 6'b001000,
        LETTER_I   = 6'b001001,
        LETTER_J   = 6'b001010,
        LETTER_K   = 6'b001011,
        LETTER_L   = 6'b001100,
        LETTER_M   = 6'b001101,
        LETTER_N   = 6'b001110,
        LETTER_O   = 6'b001111,
        LETTER_P   = 6'b010000,
        LETTER_Q   = 6'b010001,
        LETTER_R   = 6'b010010,
        LETTER_S   = 6'b010011,
        LETTER_T   = 6'b010100,
        LETTER_U   = 6'b010101,
        LETTER_V   = 6'b010110,
        LETTER_W   = 6'b010111,
        LETTER_X   = 6'b011000,
        LETTER_Y   = 6'b011001,
        LETTER_Z   = 6'b011010,
        SYMBOL_LBT = 6'b011011,
        SYMBOL_TDA = 6'b011100,
        SYMBOL_RBT = 6'b011101,
        SYMBOL_LBR = 6'b011110,
        SYMBOL_RBR = 6'b011111,
        SYMBOL_BLK = 6'b100000,
        SYMBOL_EXM = 6'b100001,
        SYMBOL_QOT = 6'b100010,
        SYMBOL_PND = 6'b100011,
        SYMBOL_USD = 6'b100100,
        SYMBOL_PCT = 6'b100101,
        SYMBOL_AMP = 6'b100110,
        SYMBOL_APT = 6'b100111,
        SYMBOL_LPR = 6'b101000,
        SYMBOL_RPR = 6'b101001,
        SYMBOL_AST = 6'b101010,
        SYMBOL_PLS = 6'b101011,
        SYMBOL_CMA = 6'b101100,
        SYMBOL_MNS = 6'b101101,
        SYMBOL_PRD = 6'b101110,
        SYMBOL_SLH = 6'b101111,
        NUMBER_0   = 6'b110000,
        NUMBER_1   = 6'b110001,
        NUMBER_2   = 6'b110010,
        NUMBER_3   = 6'b110011,
        NUMBER_4   = 6'b110100,
        NUMBER_5   = 6'b110101,
        NUMBER_6   = 6'b110110,
        NUMBER_7   = 6'b110111,
        NUMBER_8   = 6'b111000,
        NUMBER_9   = 6'b111001,
        SYMBOL_COL = 6'b111010,
        SYMBOL_SEM = 6'b111011,
        SYMBOL_LAR = 6'b111100,
        SYMBOL_EQL = 6'b111101,
        SYMBOL_RAR = 6'b111110,
        SYMBOL_QUE = 6'b111111
    }   ascii_value;

    always_ff @(posedge advance, negedge reset_active_low) begin
        if(!reset_active_low) begin
            //array_counter <= 1'b0;
            output_bus <= 6'b000000;
        end
        else begin
            //if (array_counter == (WORD_LENGTH + 1)) begin
            //    array_counter <= 1'b0;
            //end
            //else begin
            //    array_counter <= array_counter + 1'b1;
            //end
            output_bus <= output_bus + 1'b1;
        end
    end
//    
//    always_comb begin
//        word_out[0]  = LETTER_P;
//        word_out[1]  = LETTER_R;
//        word_out[2]  = LETTER_O;
//        word_out[3]  = LETTER_F;
//        word_out[4]  = SYMBOL_PRD;
//        word_out[5]  = SYMBOL_BLK;
//        word_out[6]  = LETTER_J;
//        word_out[7]  = LETTER_A;
//        word_out[8]  = LETTER_S;
//        word_out[9]  = LETTER_O;
//        word_out[10] = LETTER_N;
//        word_out[11] = SYMBOL_BLK;
//        word_out[12] = LETTER_S;
//        word_out[13] = SYMBOL_PRD;
//        word_out[14] = SYMBOL_BLK;
//        word_out[15] = LETTER_T;
//        word_out[16] = LETTER_H;
//        word_out[17] = LETTER_W;
//        word_out[18] = LETTER_E;
//        word_out[19] = LETTER_A;
//        word_out[20] = LETTER_T;
//        word_out[21] = LETTER_T;
//        word_out[22] = SYMBOL_EXM;
//        word_out[23] = NUMBER_6;
//        word_out[24] = NUMBER_7;
//        word_out[25] = SYMBOL_EXM;
//        word_out[26] = NUMBER_6;
//        word_out[27] = NUMBER_7;
//        word_out[28] = SYMBOL_EXM;
//    end
//    
//    always_comb begin
//        if (!reset_active_low) begin
//            output_bus = SYMBOL_USD;
//        end
//        else begin
//            output_bus = word_out[array_counter];
//            
//        end 
//    end
    
    assign addr_0 = output_bus[0];
    assign addr_1 = output_bus[1];
    assign addr_2 = output_bus[2];
    assign addr_3 = output_bus[3];
    assign addr_4 = output_bus[4];
    assign addr_5 = output_bus[5];
    
endmodule