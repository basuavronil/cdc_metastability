// Slow-to-Fast CDC using STRICTLY 2 Flip-Flops in total
module cdc_slow_to_fast_2ff (
    input  wire fast_clk,
    input  wire rst_n,
    input  wire pulse_slow,  // Pulse from slow clock domain
    output wire pulse_fast   // 1-cycle pulse in fast domain
);

    reg sync_ff1; // Flip-Flop 1: First stage synchronizer
    reg sync_ff2; // Flip-Flop 2: Second stage synchronizer

    // 2-Stage Synchronizer
    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= pulse_slow;
            sync_ff2 <= sync_ff1;
        end
    end

    // Edge Detection using ONLY the 2 Synchronizer Flip-Flops:
    // Output is HIGH when sync_ff1 has updated to '1' but sync_ff2 hasn't captured it yet.
    assign pulse_fast = sync_ff1 && !sync_ff2;

endmodule
