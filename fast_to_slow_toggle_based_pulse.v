// Fast-to-Slow CDC using Toggle-Based Logic + 2-FF Synchronizer
module cdc_fast_to_slow_toggle (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire rst_n,
    input  wire pulse_fast,  // 1-cycle pulse in fast domain
    output wire pulse_slow   // 1-cycle pulse regenerated in slow domain
);

    // -------------------------------------------------------------------------
    // 1. FAST DOMAIN: Convert pulse into a toggle signal
    // -------------------------------------------------------------------------
    reg toggle_fast;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_fast <= 1'b0;
        end else if (pulse_fast) begin
            toggle_fast <= ~toggle_fast; // Invert level on every pulse
        end
    end

    // -------------------------------------------------------------------------
    // 2. SLOW DOMAIN: 2-FF Synchronizer
    // -------------------------------------------------------------------------
    reg sync_ff1;
    reg sync_ff2;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= toggle_fast; // First stage FF
            sync_ff2 <= sync_ff1;    // Second stage FF
        end
    end

    // -------------------------------------------------------------------------
    // 3. SLOW DOMAIN: Edge Detector (Regenerates 1-cycle pulse)
    // -------------------------------------------------------------------------
    reg sync_ff3;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff3 <= 1'b0;
        end else begin
            sync_ff3 <= sync_ff2;
        end
    end

    // Pulse is generated whenever sync_ff2 and sync_ff3 differ (XOR)
    assign pulse_slow = sync_ff2 ^ sync_ff3;

endmodule
