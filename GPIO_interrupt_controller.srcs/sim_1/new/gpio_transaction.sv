class gpio_transaction;

    // -------------------------------------------------
    // APB transaction fields
    // -------------------------------------------------
    rand bit          write;
    rand logic [7:0]  addr;
    rand logic [31:0] data;

    // -------------------------------------------------
    // Observed values from monitor
    // -------------------------------------------------
    logic [31:0] observed_data;
    logic [7:0]  observed_addr;
    bit          observed_write;

    logic [7:0]  observed_gpio_out;
    logic [7:0]  observed_gpio_oe;
    bit          observed_irq;

    // -------------------------------------------------
    // GPIO input stimulus
    // -------------------------------------------------
    bit          is_gpio_stimulus;
    logic [7:0]  gpio_value;

    // -------------------------------------------------
    // Display transaction
    // -------------------------------------------------
    function void display();

        if (is_gpio_stimulus) begin

            $display("TRANSACTION: GPIO INPUT = 0x%02h",
                     gpio_value);

        end
        else begin

            $display("TRANSACTION: write=%0d addr=0x%02h data=0x%08h",
                     write, addr, data);

        end

    endfunction

endclass