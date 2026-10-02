interface gpio_interface #(
    parameter int NUM_PINS = 8
);

    // Clock and reset
    logic PCLK;
    logic PRESETn;

    // APB signals
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;

    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    // GPIO signals
    logic [NUM_PINS-1:0] gpio_in;
    logic [NUM_PINS-1:0] gpio_out;
    logic [NUM_PINS-1:0] gpio_oe;

    // Interrupt
    logic irq;

endinterface