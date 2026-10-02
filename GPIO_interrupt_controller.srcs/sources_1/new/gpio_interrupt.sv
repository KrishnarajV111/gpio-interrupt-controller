module gpio_interrupt #(
    parameter int NUM_PINS = 8
)(
    // Clock and reset
    input  logic PCLK,
    input  logic PRESETn,

    // GPIO input
    input  logic [NUM_PINS-1:0] gpio_in,

    // Interrupt configuration
    input  logic [NUM_PINS-1:0] int_type,
    input  logic [NUM_PINS-1:0] int_polarity,
    input  logic [NUM_PINS-1:0] int_enable,

    // Clear command from register block
    input  logic [NUM_PINS-1:0] int_clear,

    // Interrupt status and output
    output logic [NUM_PINS-1:0] int_status,
    output logic irq
);
    // Previous GPIO value, used for edge detection
    logic [NUM_PINS-1:0] prev_gpio_in;

    // Interrupt conditions
    logic [NUM_PINS-1:0] edge_event;
    logic [NUM_PINS-1:0] level_event;
    logic [NUM_PINS-1:0] interrupt_event;
        // Detect edge-triggered interrupt conditions
    always_comb begin
        edge_event = '0;

        for (int i = 0; i < NUM_PINS; i++) begin

            if (int_type[i]) begin

                // Rising edge
                if (int_polarity[i] &&
                    !prev_gpio_in[i] &&
                    gpio_in[i]) begin

                    edge_event[i] = 1'b1;
                end

                // Falling edge
                else if (!int_polarity[i] &&
                         prev_gpio_in[i] &&
                         !gpio_in[i]) begin

                    edge_event[i] = 1'b1;
                end

            end
        end
    end
        // Detect level-triggered interrupt conditions
    always_comb begin
        level_event = '0;

        for (int i = 0; i < NUM_PINS; i++) begin

            if (!int_type[i]) begin

                // High level
                if (int_polarity[i] && gpio_in[i]) begin
                    level_event[i] = 1'b1;
                end

                // Low level
                else if (!int_polarity[i] && !gpio_in[i]) begin
                    level_event[i] = 1'b1;
                end

            end
        end
    end
        // Any configured edge or level condition can create an event
    assign interrupt_event = edge_event | level_event;
        // Sticky interrupt status
    always_ff @(posedge PCLK) begin

        if (!PRESETn) begin
            prev_gpio_in <= '0;
            int_status   <= '0;
        end
        else begin

            // Remember current GPIO values for next edge detection
            prev_gpio_in <= gpio_in;

            // Clear requested bits, then latch any new events
            int_status <= (int_status & ~int_clear) | interrupt_event;

        end
    end
        // Interrupt output is the OR of all enabled pending bits
    assign irq = |(int_status & int_enable);

endmodule