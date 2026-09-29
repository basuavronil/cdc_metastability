// Clock Domain Crossing (CDC): Fast to Slow Domain Pulse Synchronizer
module cdc_fast_to_slow (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire rst_n,        // Active-low reset
    input  wire pulse_in,     // Pulse in fast clock domain
    output wire pulse_out     // Synchronized output in slow clock domain
);

    reg [3:0] counter;
    reg       p_stretcher;
    reg       sync_ff1, sync_ff2;

    // -------------------------------------------------------------------------
    // 1. Pulse Stretcher (FAST CLOCK DOMAIN)
    // -------------------------------------------------------------------------
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter     <= 4'd0;
            p_stretcher <= 1'b0;
        end else begin
            if (pulse_in) begin
                counter     <= 4'd10; // Stretch duration
                p_stretcher <= 1'b1;  // Assert immediately on trigger
            end else if (counter != 4'd0) begin
                counter     <= counter - 1'b1;
                p_stretcher <= 1'b1;  // Hold high while counter > 0
            end else begin
                p_stretcher <= 1'b0;  // Deassert when counter reaches 0
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2. 2-Flip-Flop Synchronizer (SLOW CLOCK DOMAIN)
    // -------------------------------------------------------------------------
    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= p_stretcher;
            sync_ff2 <= sync_ff1;
        end
    end

    // Assign synchronized signal to module output
    assign pulse_out = sync_ff2;

endmodule
