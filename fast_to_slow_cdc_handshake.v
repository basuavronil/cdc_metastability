// Clock Domain Crossing: Handshake-Based Pulse Synchronizer (REQ/ACK)
module cdc_handshake (
    input  wire fast_clk,
    input  wire slow_clk,
    input  wire rst_n,
    input  wire pulse_fast,  // Pulse input in fast domain
    output reg  busy,        // High when processing a handshake (cannot accept new pulse)
    output wire pulse_slow   // Synchronized pulse output in slow domain
);

    // -------------------------------------------------------------------------
    // 1. FAST CLOCK DOMAIN: Request & Acknowledgement Sync
    // -------------------------------------------------------------------------
    reg req_fast;
    reg ack_sync1_fast, ack_sync2_fast;

    always @(posedge fast_clk or negedge rst_n) begin
        if (!rst_n) begin
            req_fast       <= 1'b0;
            busy           <= 1'b0;
            ack_sync1_fast <= 1'b0;
            ack_sync2_fast <= 1'b0;
        end else begin
            // Synchronize ACK back into Fast Clock Domain (2-FF)
            ack_sync1_fast <= ack_slow;
            ack_sync2_fast <= ack_sync1_fast;

            // Generate REQ logic
            if (pulse_fast && !busy) begin
                req_fast <= 1'b1;
                busy     <= 1'b1; // Lock incoming requests until current transaction finishes
            end else if (ack_sync2_fast) begin
                req_fast <= 1'b0; // Deassert REQ once ACK is detected
            end else if (!req_fast && !ack_sync2_fast) begin
                busy     <= 1'b0; // Handshake complete, clear busy signal
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2. SLOW CLOCK DOMAIN: Synchronize REQ & Generate Pulse/ACK
    // -------------------------------------------------------------------------
    reg req_sync1_slow, req_sync2_slow, req_sync3_slow;
    reg ack_slow;

    always @(posedge slow_clk or negedge rst_n) begin
        if (!rst_n) begin
            req_sync1_slow <= 1'b0;
            req_sync2_slow <= 1'b0;
            req_sync3_slow <= 1'b0;
            ack_slow       <= 1'b0;
        end else begin
            // Synchronize REQ into Slow Clock Domain (2-FF + 1 delay FF for pulse gen)
            req_sync1_slow <= req_fast;
            req_sync2_slow <= req_sync1_slow;
            req_sync3_slow <= req_sync2_slow;

            // Send ACK back to fast domain as long as REQ is observed
            ack_slow <= req_sync2_slow;
        end
    end

    // Generate 1-cycle pulse in slow domain on rising edge of synchronized REQ
    assign pulse_slow = req_sync2_slow && !req_sync3_slow;

endmodule
