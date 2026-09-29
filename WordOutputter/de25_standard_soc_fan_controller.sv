// =============================================================================
// fan_ctrl_fixed.sv
// -----------------------------------------------------------------------------
// Fixed-speed SoC fan controller for the Terasic DE25-Standard (Agilex 5)
// Self-contained: all sub-modules consolidated into one file.
//
// Author      : Daniel J. Lomis
//               Bradley Department of Electrical and Computer Engineering
//               Virginia Polytechnic Institute and State University
//
// Description :
//   Controls the on-board SoC fan via the MAX6650 fan IC over the FPGA I2C
//   bus (FPGA_I2C_SCLK / FPGA_I2C_SDAT).  Locks the fan to a fixed RPM set
//   by TARGET_RPM at synthesis time.  Also reads board temperatures from the
//   TMP442 sensor and makes them available as outputs.
//
//   Top-level module : FAN_CTRL_FIXED
//   Sub-modules (all in this file, in dependency order):
//     1. clk_div          — 50 MHz → 400 kHz clock divider
//     2. fan_startup_timer — 0.5 s alarm-enable delay after reset
//     3. i2c_write_ptr    — I2C write-pointer transaction
//     4. i2c_write_byte   — I2C write-byte transaction
//     5. i2c_read_byte    — I2C read-byte transaction
//     6. FAN_CTRL_FIXED   — top-level controller (instantiates all above)
//
// ─── Integration into golden_top.v ───────────────────────────────────────────
//
//   1. Add these wires near the top of golden_top:
//
//        wire signed [15:0] w_fpga_temp;
//        wire signed [15:0] w_board_temp;
//        wire signed [15:0] w_board2_temp;
//        wire        [15:0] w_fan_rpm;
//        wire               w_i2c_ready;
//
//   2. Replace the BOARD_MANAGEMENT instantiation with:
//
//        FAN_CTRL_FIXED #(
//            .TARGET_RPM (4500)          // <-- set your desired RPM here
//        ) u_fan_ctrl (
//            .clk_50          (CLOCK0_50),
//            .reset_n         (sys_reset_n),
//            .I2C_SCL         (FPGA_I2C_SCLK),
//            .I2C_SDA         (FPGA_I2C_SDAT),
//            .FPGA_Temperature  (w_fpga_temp),
//            .Board_Temperature (w_board_temp),
//            .Board2_Temperature(w_board2_temp),
//            .Fan_Speed         (w_fan_rpm),
//            .I2C_READY         (w_i2c_ready)
//        );
//
//   3. Pass w_fpga_temp / w_board_temp / w_board2_temp / w_fan_rpm into your
//      NiosV system exactly as BOARD_MANAGEMENT did before (same port names,
//      same widths).  Remove the Auto_Fan_Speed and Set_Fan_Speed ports from
//      the Qsys system, or tie them off — they are no longer used.
//
//   4. Remove from your Quartus project (no longer needed):
//        BOARD_MANAGEMENT.v, auto_fan.v, fan_timer.v,
//        CLOCKMEM.v, I2C_READ_DATA.v, I2C_WRITE_BYTE.v, I2C_WRITE_POINTER.v
//
// ─── TARGET_RPM quick-reference (KSCALE = 2) ─────────────────────────────────
//   Formula: KTACH = floor(119040 / RPM) − 1
//
//   TARGET_RPM │ KTACH  │ Actual RPM
//   ───────────┼────────┼──────────────
//     3 500    │ 8'h21  │ ~3 501 RPM   ← board minimum
//     4 000    │ 8'h1C  │ ~4 105 RPM
//     4 500    │ 8'h19  │ ~4 578 RPM   ← default
//     5 000    │ 8'h16  │ ~5 176 RPM
//     5 500    │ 8'h14  │ ~5 669 RPM
//     6 000    │ 8'h12  │ ~6 265 RPM   ← board maximum
//
// Version History:
//   v1.0  2026-09-13  DJL  Initial release — consolidated from Terasic sources
// =============================================================================


// =============================================================================
// 1. clk_div
//    50 MHz input → toggled output at CLK_FREQ half-period counts.
//    Instantiated as: clk_div #(.CLK_FREQ(125)) → 50 MHz / (125*2) = 400 kHz
// =============================================================================
module clk_div #(
    parameter int unsigned CLK_FREQ = 125   // half-period tick count
) (
    input  logic reset_n,
    input  logic clk,
    output logic ck_out
);
    logic [31:0] delay;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            ck_out <= 1'b0;
            delay  <= '0;
        end else begin
            if (delay > (CLK_FREQ >> 1)) begin
                delay  <= '0;
                ck_out <= ~ck_out;
            end else begin
                delay <= delay + 1'b1;
            end
        end
    end
endmodule : clk_div


// =============================================================================
// 2. fan_startup_timer
//    Asserts TIME_OUT ~0.5 s after reset (at 400 kHz: 400000/2 ticks).
//    Used to delay enabling MAX6650 alarm until the fan is spinning.
// =============================================================================
module fan_startup_timer (
    input  logic reset_n,
    input  logic clk,        // 400 kHz
    output logic time_out
);
    logic [31:0] delay;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            time_out <= 1'b0;
            delay    <= '0;
        end else begin
            if (delay < 32'd200_000)   // 400000/2 ticks ≈ 0.5 s
                delay <= delay + 1'b1;
            else
                time_out <= 1'b1;
        end
    end
endmodule : fan_startup_timer


// =============================================================================
// 3. i2c_write_ptr
//    Sends a two-byte I2C write-pointer (START + slave addr + pointer + STOP).
//    Used to set the register address before a read.
// =============================================================================
module i2c_write_ptr (
    input  logic        reset_n,
    input  logic        pt_ck,          // 400 kHz I2C clock
    input  logic        go,
    input  logic [7:0]  pointer,
    input  logic [7:0]  slave_address,
    input  logic        sdai,
    output logic        sdao,
    output logic        sclo,
    output logic        end_ok,
    output logic        no_ack
);
    logic [5:0] st;
    logic [3:0] cnt;
    logic [2:0] byte_cnt;
    logic [8:0] shift_a;
    logic [3:0] dely;

    always_ff @(posedge pt_ck or negedge reset_n) begin
        if (!reset_n) begin
            no_ack  <= 1'b0; st <= '0; sdao <= 1'b1; sclo <= 1'b1;
            cnt <= '0; end_ok <= 1'b1; byte_cnt <= '0;
        end else case (st)
            0: begin
                sdao <= 1'b1; sclo <= 1'b1; cnt <= '0;
                end_ok <= 1'b1; byte_cnt <= '0;
                if (go) st <= 6'd30;
            end
            1: begin st <= 2; {sdao,sclo} <= 2'b01;
                     shift_a <= {slave_address, 1'b1}; end
            2: begin st <= 3; {sdao,sclo} <= 2'b00; end
            3: begin st <= 4; {sdao, shift_a} <= {shift_a, 1'b0}; end
            4: begin st <= 5; sclo <= 1'b1; cnt <= cnt + 1'b1; end
            5: begin
                sclo <= 1'b0;
                if (cnt == 4'd9) begin
                    if (byte_cnt == 3'd1) st <= 6;
                    else begin
                        cnt <= '0; byte_cnt <= 3'd1;
                        shift_a <= {pointer, 1'b1}; st <= 2;
                    end
                end else st <= 2;
            end
            6:  begin st <= 7;  {sdao,sclo} <= 2'b00; end
            7:  begin st <= 8;  {sdao,sclo} <= 2'b01; end
            8:  begin st <= 9;  {sdao,sclo} <= 2'b11; end
            9:  begin st <= 30; sdao <= 1'b1; sclo <= 1'b1;
                      cnt <= '0; end_ok <= 1'b1; byte_cnt <= '0; end
            // ack-poll re-entry (states 31–36 from original)
            30: begin if (!go) st <= 31; end
            31: begin end_ok <= 1'b0; cnt <= '0; st <= 32;
                      {sdao,sclo} <= 2'b01;
                      shift_a <= {slave_address, 1'b1}; end
            32: begin st <= 33; {sdao,sclo} <= 2'b00; end
            33: begin st <= 34; {sdao, shift_a} <= {shift_a, 1'b0}; end
            34: begin st <= 35; sclo <= 1'b1; cnt <= cnt + 1'b1; end
            35: begin
                if (cnt == 4'd9) begin dely <= '0; st <= 36; end
                else             begin st <= 32; sclo <= 1'b0; end
            end
            36: begin
                dely <= dely + 1'b1;
                if (dely > 4'd1) begin
                    if (sdai) begin no_ack <= 1'b1; st <= 31; {sdao,sclo} <= 2'b11; end
                    else       begin st <= 5; sclo <= 1'b0; end
                end
            end
            default: st <= '0;
        endcase
    end
endmodule : i2c_write_ptr


// =============================================================================
// 4. i2c_write_byte
//    Sends a three-byte I2C write: slave addr + register pointer + data byte.
// =============================================================================
module i2c_write_byte (
    input  logic        reset_n,
    input  logic        pt_ck,
    input  logic        go,
    input  logic [7:0]  pointer,
    input  logic [7:0]  slave_address,
    input  logic [7:0]  wdata8,
    input  logic        sdai,
    output logic        sdao,
    output logic        sclo,
    output logic        end_ok,
    output logic        no_ack
);
    logic [5:0] st;
    logic [3:0] cnt;
    logic [2:0] byte_cnt;
    logic [8:0] shift_a;

    always_ff @(posedge pt_ck or negedge reset_n) begin
        if (!reset_n) begin
            no_ack <= 1'b0; st <= '0; sdao <= 1'b1; sclo <= 1'b1;
            cnt <= '0; end_ok <= 1'b1; byte_cnt <= '0;
        end else case (st)
            0: begin
                sdao <= 1'b1; sclo <= 1'b1; cnt <= '0;
                end_ok <= 1'b1; byte_cnt <= '0;
                if (go) st <= 6'd30;
            end
            1: begin st <= 2; {sdao,sclo} <= 2'b01;
                     shift_a <= {slave_address, 1'b1}; end
            2: begin st <= 3; {sdao,sclo} <= 2'b00; end
            3: begin st <= 4; {sdao, shift_a} <= {shift_a, 1'b0}; end
            4: begin st <= 5; sclo <= 1'b1; cnt <= cnt + 1'b1; end
            5: begin
                sclo <= 1'b0;
                if (cnt == 4'd9) begin
                    if (byte_cnt == 3'd2) st <= 6;
                    else begin
                        cnt <= '0; st <= 2;
                        if      (byte_cnt == 3'd0) begin byte_cnt <= 3'd1; shift_a <= {pointer, 1'b1}; end
                        else if (byte_cnt == 3'd1) begin byte_cnt <= 3'd2; shift_a <= {wdata8,  1'b1}; end
                    end
                    no_ack <= sdai;
                end else st <= 2;
            end
            6:  begin st <= 7;  {sdao,sclo} <= 2'b00; end
            7:  begin st <= 8;  {sdao,sclo} <= 2'b01; end
            8:  begin st <= 9;  {sdao,sclo} <= 2'b11; end
            9:  begin st <= 30; sdao <= 1'b1; sclo <= 1'b1;
                      cnt <= '0; end_ok <= 1'b1; byte_cnt <= '0; end
            30: begin if (!go) st <= 31; end
            31: begin end_ok <= 1'b0; st <= 1; end
            default: st <= '0;
        endcase
    end
endmodule : i2c_write_byte


// =============================================================================
// 5. i2c_read_byte
//    Performs a full I2C read: re-sends slave addr with R/W=1, clocks in 8
//    data bits, sends NACK, sends STOP.
// =============================================================================
module i2c_read_byte (
    input  logic        reset_n,
    input  logic        pt_ck,
    input  logic        go,
    input  logic [7:0]  slave_address,
    input  logic        sdai,
    output logic        sdao,
    output logic        sclo,
    output logic        end_ok,
    output logic [7:0]  data,
    output logic        no_ack
);
    logic [5:0] st;
    logic [3:0] cnt;
    logic [3:0] byte_cnt;
    logic [8:0] shift_a;
    logic [7:0] dely;

    always_ff @(posedge pt_ck or negedge reset_n) begin
        if (!reset_n) begin
            no_ack <= 1'b0; st <= '0; sdao <= 1'b1; sclo <= 1'b1;
            cnt <= '0; end_ok <= 1'b1; byte_cnt <= '0; data <= '0;
        end else case (st)
            0: begin
                sdao <= 1'b1; sclo <= 1'b1; cnt <= '0;
                end_ok <= 1'b1; byte_cnt <= '0; data <= '0;
                if (go) st <= 6'd30;
            end
            // address phase (read command: slave | 1)
            1: begin st <= 2; {sdao,sclo} <= 2'b01;
                     shift_a <= {slave_address | 8'h01, 1'b1}; end
            2: begin st <= 3; {sdao,sclo} <= 2'b00; end
            3: begin st <= 4; {sdao, shift_a} <= {shift_a, 1'b0}; end
            4: begin st <= 5; sclo <= 1'b1; cnt <= cnt + 1'b1; end
            5: begin sclo <= 1'b0;
                if (cnt == 4'd9) begin st <= 6; no_ack <= sdai; end
                else             st <= 2;
            end
            // data phase
            6:  begin st <= 7; {sdao,sclo} <= 2'b10; cnt <= '0; end
            7:  begin st <= 8; sclo <= 1'b1; dely <= '0;
                      if (cnt != 4'd8) data <= {data[6:0], sdai};
                      cnt <= cnt + 1'b1; end
            8:  begin
                dely <= dely + 1'b1; sclo <= 1'b0;
                if (dely == 8'd2) begin
                    if      (cnt == 4'd8)  begin sdao <= (byte_cnt == 4'd0) ? 1'b1 : 1'b0; st <= 7; end
                    else if (cnt == 4'd9)  begin byte_cnt <= byte_cnt + 1'b1; st <= 9; end
                    else                   st <= 7;
                end
            end
            9:  begin if (byte_cnt > 4'd0) st <= 10; else st <= 6; end
            10: begin st <= 11; {sdao,sclo} <= 2'b00; end
            11: begin st <= 12; {sdao,sclo} <= 2'b01; end
            12: begin st <= 13; {sdao,sclo} <= 2'b11; end
            13: begin st <= 30; end_ok <= 1'b1; sdao <= 1'b1; sclo <= 1'b1;
                      cnt <= '0; byte_cnt <= '0; end
            30: begin if (!go) st <= 31; end
            31: begin st <= 1; end_ok <= 1'b0; end
            default: st <= '0;
        endcase
    end
endmodule : i2c_read_byte


// =============================================================================
// 6. FAN_CTRL_FIXED  —  top-level
// =============================================================================
module FAN_CTRL_FIXED #(
    parameter int unsigned TARGET_RPM = 4500,   // Fan set-point [3500–6000 RPM]
    parameter int unsigned KSCALE     = 2        // Must match MAX6650 CONFIG reg
) (
    input  logic        clk_50,         // 50 MHz board clock (CLOCK0_50)
    input  logic        reset_n,        // Active-low reset (sys_reset_n)

    // MAX6650 + TMP442 share this I2C bus
    inout  wire         I2C_SCL,        // FPGA_I2C_SCLK
    inout  wire         I2C_SDA        // FPGA_I2C_SDAT

    // Sensor outputs (same widths as original BOARD_MANAGEMENT ports)
);
    // -------------------------------------------------------------------------
    // KTACH synthesis constant
    // KTACH = floor((992 * KSCALE * 60) / TARGET_RPM) - 1
    // -------------------------------------------------------------------------
    localparam logic [7:0] KTACH_FIXED =
        8'(((992 * KSCALE * 60) / TARGET_RPM) - 1);

    // -------------------------------------------------------------------------
    // Parameters — I2C device addresses and register map
    // -------------------------------------------------------------------------
    // TMP442 temperature sensor
    localparam logic [7:0] SLAVE_ADDR_TA = 8'h98;
    localparam logic [7:0] PA_CONF1      = 8'h09;
    localparam logic [7:0] PA_CONF2      = 8'h0A;
    localparam logic [7:0] PA_RATE       = 8'h0B;
    localparam logic [7:0] PA_MFG_ID     = 8'hFE;
    localparam logic [7:0] PA_DEV_ID     = 8'hFF;
    localparam logic [7:0] PA_LOCT1_H    = 8'h00;
    localparam logic [7:0] PA_REMT1_H    = 8'h01;
    localparam logic [7:0] PA_REMT2_H    = 8'h02;
    localparam logic [7:0] PA_STATUS     = 8'h08;
    localparam logic [7:0] PA_SFRESET    = 8'hFC;

    // MAX6650 fan controller
    localparam logic [7:0] SLAVE_ADDR_F   = 8'h90;
    localparam logic [7:0] P_SPEED        = 8'h00;
    localparam logic [7:0] P_CONFIG       = 8'h02;
    localparam logic [7:0] P_GPIO_DEF     = 8'h04;
    localparam logic [7:0] P_DAC          = 8'h06;
    localparam logic [7:0] P_ALARM_ENABLE = 8'h08;
    localparam logic [7:0] P_ALARM        = 8'h0A;
    localparam logic [7:0] P_TACH0        = 8'h0C;
    localparam logic [7:0] P_TACH1        = 8'h0E;
    localparam logic [7:0] P_COUNT        = 8'h16;

    // MAX6650 config values
    localparam logic [7:0] CFG_CONFIG      = 8'h29; // closed-loop, KSCALE=2
    localparam logic [7:0] CFG_GPIO_DEF    = 8'hF5;
    localparam logic [7:0] CFG_ALARM_ENABLE= 8'h0F;
    localparam logic [7:0] CFG_COUNT       = 8'h01; // 0.5 s count window

    localparam int READ_MAX  = 10;
    localparam int WRITE_MAX = 10;

    // -------------------------------------------------------------------------
    // 400 kHz clock
    // -------------------------------------------------------------------------
    logic clk_400k;
    clk_div #(.CLK_FREQ(125)) u_clkdiv (
        .reset_n (1'b1),
        .clk     (clk_50),
        .ck_out  (clk_400k)
    );

    // -------------------------------------------------------------------------
    // Startup delay — hold off alarm enable until fan is spinning
    // -------------------------------------------------------------------------
    logic can_enable_alarm;
    fan_startup_timer u_timer (
        .reset_n  (reset_n),
        .clk      (clk_400k),
        .time_out (can_enable_alarm)
    );

    // -------------------------------------------------------------------------
    // I2C bus wiring (open-drain)
    // -------------------------------------------------------------------------
    logic sdao_wptr, sclo_wptr;
    logic sdao_wbyt, sclo_wbyt;
    logic sdao_rdat, sclo_rdat;

    logic sclo_bus, sdao_bus;
    assign sclo_bus = sclo_wptr & sclo_wbyt & sclo_rdat;
    assign sdao_bus = sdao_wptr & sdao_wbyt & sdao_rdat;

    assign I2C_SCL = sclo_bus ? 1'bz : 1'b0;
    assign I2C_SDA = sdao_bus ? 1'bz : 1'b0;

    // -------------------------------------------------------------------------
    // I2C sub-module control signals
    // -------------------------------------------------------------------------
    logic        wptr_go,  wptr_end;
    logic        wbyt_go,  wbyt_end;
    logic        rdat_go,  rdat_end;
    logic [7:0]  rdat_out;
    logic [7:0]  slave_addr_r, ptr_reg_r, word_data_r;

    i2c_write_ptr u_wptr (
        .reset_n      (reset_n),
        .pt_ck        (clk_400k),
        .go           (wptr_go),
        .pointer      (ptr_reg_r),
        .slave_address(slave_addr_r),
        .sdai         (I2C_SDA),
        .sdao         (sdao_wptr),
        .sclo         (sclo_wptr),
        .end_ok       (wptr_end),
        .no_ack       ()
    );

    i2c_write_byte u_wbyt (
        .reset_n      (reset_n),
        .pt_ck        (clk_400k),
        .go           (wbyt_go),
        .pointer      (ptr_reg_r),
        .slave_address(slave_addr_r),
        .wdata8       (word_data_r),
        .sdai         (I2C_SDA),
        .sdao         (sdao_wbyt),
        .sclo         (sclo_wbyt),
        .end_ok       (wbyt_end),
        .no_ack       ()
    );

    i2c_read_byte u_rdat (
        .reset_n      (reset_n),
        .pt_ck        (clk_400k),
        .go           (rdat_go),
        .slave_address(slave_addr_r),
        .sdai         (I2C_SDA),
        .sdao         (sdao_rdat),
        .sclo         (sclo_rdat),
        .end_ok       (rdat_end),
        .data         (rdat_out),
        .no_ack       ()
    );

    // -------------------------------------------------------------------------
    // Internal sensor / fan registers
    // -------------------------------------------------------------------------
    logic [7:0]  tach0_r, tach1_r, dac_r, alarm_r;
    logic signed [7:0] loct1_h_r, remt1_h_r, remt2_h_r;
    logic [7:0]  status_r, mfg_id_r, dev_id_r;

    // -------------------------------------------------------------------------
    // Main controller FSM
    // -------------------------------------------------------------------------
    logic [7:0] st, cnt, wcnt;
    logic [31:0] dely;
    logic do_config;
    logic temp_valid;

    always_ff @(posedge clk_400k or negedge reset_n) begin
        if (!reset_n) begin
            st          <= '0;
            cnt         <= '0;
            wcnt        <= '0;
            dely        <= '0;
            do_config   <= 1'b0;
            temp_valid  <= 1'b0;
            wptr_go     <= 1'b1;
            rdat_go     <= 1'b1;
            wbyt_go     <= 1'b1;
            slave_addr_r<= '0;
            ptr_reg_r   <= '0;
            word_data_r <= '0;
        end else case (st)

            // ── INIT ──────────────────────────────────────────────────────
            8'd0: begin
                st <= 8'd30;
                wptr_go <= 1'b1; rdat_go <= 1'b1; wbyt_go <= 1'b1;
                cnt <= '0; wcnt <= '0; dely <= '0; do_config <= 1'b0;
            end

            // ── READ LOOP (states 1–11) ────────────────────────────────
            8'd1: st <= 8'd2;

            8'd2: begin
                // Select register to read
                case (cnt)
                    8'd0: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_F, P_ALARM };
                    8'd1: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_F, P_TACH0 };
                    8'd2: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_F, P_TACH1 };
                    8'd3: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_F, P_DAC   };
                    8'd4: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_TA, PA_MFG_ID  };
                    8'd5: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_TA, PA_DEV_ID  };
                    8'd6: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_TA, PA_STATUS  };
                    8'd7: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_TA, PA_LOCT1_H };
                    8'd8: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_TA, PA_REMT1_H };
                    8'd9: {slave_addr_r, ptr_reg_r} <= {SLAVE_ADDR_TA, PA_REMT2_H };
                    default: ;
                endcase
                if (wptr_end) begin wptr_go <= 1'b0; st <= 8'd3; dely <= '0; end
            end

            8'd3: begin
                dely <= dely + 1'b1;
                if (dely == 32'd2) begin wptr_go <= 1'b1; st <= 8'd4; end
            end

            8'd4: if (wptr_end) st <= 8'd5;

            8'd5: st <= 8'd6;

            8'd6: begin
                if (rdat_end) begin rdat_go <= 1'b0; st <= 8'd7; dely <= '0; end
            end

            8'd7: begin
                dely <= dely + 1'b1;
                if (dely == 32'd2) begin rdat_go <= 1'b1; st <= 8'd8; end
            end

            8'd8: st <= 8'd9;

            8'd9: begin
                if (rdat_end) begin
                    case (cnt)
                        8'd0: alarm_r   <= rdat_out;
                        8'd1: tach0_r   <= rdat_out;
                        8'd2: tach1_r   <= rdat_out;
                        8'd3: dac_r     <= rdat_out;
                        8'd4: mfg_id_r  <= rdat_out;
                        8'd5: dev_id_r  <= rdat_out;
                        8'd6: status_r  <= rdat_out;
                        8'd7: loct1_h_r <= signed'(rdat_out);
                        8'd8: remt1_h_r <= signed'(rdat_out);
                        8'd9: remt2_h_r <= signed'(rdat_out);
                        default: ;
                    endcase
                    cnt <= cnt + 8'd1;
                    st  <= 8'd10;
                end
            end

            8'd10: begin
                if (cnt == READ_MAX) begin
                    temp_valid <= 1'b1;
                    cnt        <= 8'd2;
                    st         <= 8'd11;
                end else if ((cnt == 8'd2) && !do_config) begin
                    st <= 8'd30;   // go configure before continuing reads
                end else begin
                    st <= 8'd1;
                    if ((cnt == 8'd7) && status_r[7]) cnt <= 8'd6; // busy retry
                end
                dely    <= '0;
                wptr_go <= 1'b1; rdat_go <= 1'b1; wbyt_go <= 1'b1;
            end

            8'd11: begin
                dely <= dely + 1'b1;
                if (dely == 32'd20) begin st <= 8'd29; temp_valid <= 1'b0; end
            end

            // ── WRITE LOOP (states 29–37) ──────────────────────────────
            8'd29: begin
                if (dely < 32'd10) dely <= dely + 1'b1;
                else               st   <= 8'd31;
            end

            8'd30: st <= 8'd31;

            8'd31: begin
                // Select register + data to write
                case (wcnt)
                    // TMP442 init
                    8'd0: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_TA,PA_SFRESET,8'hFF};
                    8'd1: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_TA,PA_CONF1,  8'h00};
                    8'd2: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_TA,PA_CONF2,  8'h3C};
                    8'd3: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_TA,PA_RATE,   8'h0B};
                    // MAX6650 init
                    8'd4: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_F, P_COUNT,      CFG_COUNT      };
                    8'd5: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_F, P_CONFIG,      8'h0A          };
                    8'd6: begin
                        if ((tach0_r > 8'd50) || can_enable_alarm) begin
                            do_config <= 1'b1;
                            {slave_addr_r,ptr_reg_r,word_data_r} <=
                                {SLAVE_ADDR_F, P_ALARM_ENABLE, CFG_ALARM_ENABLE};
                        end
                    end
                    8'd7: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_F, P_CONFIG,      CFG_CONFIG     };
                    8'd8: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_F, P_GPIO_DEF,    CFG_GPIO_DEF   };
                    // ── FIXED SPEED: always write KTACH_FIXED ──
                    8'd9: {slave_addr_r,ptr_reg_r,word_data_r}<={SLAVE_ADDR_F, P_SPEED,        KTACH_FIXED   };
                    default: ;
                endcase
                if (wbyt_end) begin wbyt_go <= 1'b0; st <= 8'd32; dely <= '0; end
            end

            8'd32: begin
                dely <= dely + 1'b1;
                if (dely == 32'd5) begin wbyt_go <= 1'b1; st <= 8'd33; end
            end

            8'd33: st <= 8'd34;

            8'd34: begin
                if (wbyt_end) begin wcnt <= wcnt + 8'd1; st <= 8'd35; end
            end

            8'd35: begin
                if ((wcnt == 8'd7) && !do_config) begin
                    st   <= 8'd1;
                    wcnt <= 8'd5;
                    cnt  <= 8'd0;
                end else if (wcnt != WRITE_MAX) begin
                    st <= 8'd31;
                end else begin
                    st   <= 8'd36;
                    wcnt <= WRITE_MAX - 1;
                    cnt  <= 8'd0;
                    dely <= '0;
                end
            end

            // ── STEADY-STATE LOOP DELAY (~0.5 s) ──────────────────────
            8'd36: begin
                if (dely == 32'd200_000) st <= 8'd37;
                else                     dely <= dely + 1'b1;
            end

            8'd37: begin
                // Re-write KTACH every loop to maintain set-point
                {slave_addr_r,ptr_reg_r,word_data_r} <=
                    {SLAVE_ADDR_F, P_SPEED, KTACH_FIXED};
                st   <= 8'd1;
                wcnt <= WRITE_MAX - 1;
                cnt  <= 8'd0;
            end

            default: st <= 8'd0;
        endcase
    end

endmodule : FAN_CTRL_FIXED