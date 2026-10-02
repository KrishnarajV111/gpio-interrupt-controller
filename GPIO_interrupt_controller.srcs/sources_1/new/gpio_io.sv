module gpio_io #(
    parameter int NUM_PINS = 8
)(
    input  logic [NUM_PINS-1:0] data_out,
    input  logic [NUM_PINS-1:0] dir,

    output logic [NUM_PINS-1:0] gpio_out,
    output logic [NUM_PINS-1:0] gpio_oe
);

    // Connect output data to GPIO output
    assign gpio_out = data_out;

    // DIR controls whether the GPIO is enabled as an output
    assign gpio_oe = dir;

endmodule