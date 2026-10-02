module gpio_registers #(
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

    // GPIO input
    input logic [NUM_PINS-1:0] gpio_in,

    // Interrupt status / clear interface
    input  logic [NUM_PINS-1:0] int_status,
    output logic [NUM_PINS-1:0] int_clear,

    // Configuration outputs
    output logic [NUM_PINS-1:0] data_out,
    output logic [NUM_PINS-1:0] dir,
    output logic [NUM_PINS-1:0] int_type,
    output logic [NUM_PINS-1:0] int_polarity,
    output logic [NUM_PINS-1:0] int_enable
);
        // APB response
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;
    
        // Register addresses
    localparam logic [7:0] ADDR_DATA_IN      = 8'h00;
    localparam logic [7:0] ADDR_DATA_OUT     = 8'h04;
    localparam logic [7:0] ADDR_DIR          = 8'h08;
    localparam logic [7:0] ADDR_INT_TYPE     = 8'h0C;
    localparam logic [7:0] ADDR_INT_POLARITY = 8'h10;
    localparam logic [7:0] ADDR_INT_ENABLE   = 8'h14;
    localparam logic [7:0] ADDR_INT_STATUS   = 8'h18;
    localparam logic [7:0] ADDR_INT_CLEAR    = 8'h1C;
    
        // Register write logic
    always_ff @(posedge PCLK) begin
        if (!PRESETn) begin
            data_out     <= '0;
            dir          <= '0;
            int_type     <= '0;
            int_polarity <= '0;
            int_enable   <= '0;
        end
        else begin
            if (PSEL && PENABLE && PWRITE) begin

                case (PADDR)

                    ADDR_DATA_OUT: begin
                        data_out <= PWDATA[NUM_PINS-1:0];
                    end

                    ADDR_DIR: begin
                        dir <= PWDATA[NUM_PINS-1:0];
                    end

                    ADDR_INT_TYPE: begin
                        int_type <= PWDATA[NUM_PINS-1:0];
                    end

                    ADDR_INT_POLARITY: begin
                        int_polarity <= PWDATA[NUM_PINS-1:0];
                    end

                    ADDR_INT_ENABLE: begin
                        int_enable <= PWDATA[NUM_PINS-1:0];
                    end

                    default: begin
                        // No writable register at this address
                    end

                endcase
            end
        end
    end
        // APB read logic and interrupt clear command
    always_comb begin

        // Default values
        PRDATA   = 32'h00000000;
        int_clear = '0;

        // APB access phase
        if (PSEL && PENABLE) begin

            // Read operation
            if (!PWRITE) begin
                case (PADDR)

                    ADDR_DATA_IN: begin
                        PRDATA[NUM_PINS-1:0] = gpio_in;
                    end

                    ADDR_DATA_OUT: begin
                        PRDATA[NUM_PINS-1:0] = data_out;
                    end

                    ADDR_DIR: begin
                        PRDATA[NUM_PINS-1:0] = dir;
                    end

                    ADDR_INT_TYPE: begin
                        PRDATA[NUM_PINS-1:0] = int_type;
                    end

                    ADDR_INT_POLARITY: begin
                        PRDATA[NUM_PINS-1:0] = int_polarity;
                    end

                    ADDR_INT_ENABLE: begin
                        PRDATA[NUM_PINS-1:0] = int_enable;
                    end

                    ADDR_INT_STATUS: begin
                        PRDATA[NUM_PINS-1:0] = int_status;
                    end

                    default: begin
                        PRDATA = 32'h00000000;
                    end

                endcase
            end

            // Write-1-to-clear command
            else begin
                if (PADDR == ADDR_INT_CLEAR) begin
                    int_clear = PWDATA[NUM_PINS-1:0];
                end
            end

        end
    end
  
endmodule