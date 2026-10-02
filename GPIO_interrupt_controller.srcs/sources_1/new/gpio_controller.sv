module gpio_controller #(
    parameter int NUM_PINS = 8
)(
    // Clock and reset
    input  logic PCLK,
    input  logic PRESETn,

    // APB interface
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [7:0]  PADDR,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR,

    // GPIO pins
    input  logic [NUM_PINS-1:0]  gpio_in,
    output logic [NUM_PINS-1:0]  gpio_out,
    output logic [NUM_PINS-1:0]  gpio_oe,

    // Interrupt
    output logic irq
);
    // Internal connections between modules
    logic [NUM_PINS-1:0] data_out;
    logic [NUM_PINS-1:0] dir;
    logic [NUM_PINS-1:0] int_type;
    logic [NUM_PINS-1:0] int_polarity;
    logic [NUM_PINS-1:0] int_enable;
    logic [NUM_PINS-1:0] int_status;
    logic [NUM_PINS-1:0] int_clear;

    logic reg_pready;
    logic reg_pslverr;
        // Register block
    gpio_registers #(
        .NUM_PINS(NUM_PINS)
    ) u_gpio_registers (
        .PCLK          (PCLK),
        .PRESETn       (PRESETn),

        .PSEL          (PSEL),
        .PENABLE       (PENABLE),
        .PWRITE        (PWRITE),
        .PADDR         (PADDR),
        .PWDATA        (PWDATA),
        .PRDATA        (PRDATA),
        .PREADY        (reg_pready),
        .PSLVERR       (reg_pslverr),

        .gpio_in       (gpio_in),

        .int_status    (int_status),
        .int_clear     (int_clear),

        .data_out      (data_out),
        .dir           (dir),
        .int_type      (int_type),
        .int_polarity  (int_polarity),
        .int_enable    (int_enable)
    );
        // Interrupt block
    gpio_interrupt #(
        .NUM_PINS(NUM_PINS)
    ) u_gpio_interrupt (
        .PCLK         (PCLK),
        .PRESETn      (PRESETn),

        .gpio_in      (gpio_in),

        .int_type     (int_type),
        .int_polarity (int_polarity),
        .int_enable   (int_enable),

        .int_clear    (int_clear),

        .int_status   (int_status),
        .irq          (irq)
    );
        // GPIO output block
    gpio_io #(
        .NUM_PINS(NUM_PINS)
    ) u_gpio_io (
        .data_out (data_out),
        .dir      (dir),
        .gpio_out (gpio_out),
        .gpio_oe  (gpio_oe)
    );
        // APB response connections
    assign PREADY  = reg_pready;
    assign PSLVERR = reg_pslverr;
endmodule
