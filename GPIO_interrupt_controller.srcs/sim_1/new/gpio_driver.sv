class gpio_driver;

    // Interface used to drive the DUT
    virtual gpio_interface vif;

    // Mailbox from generator to driver
    mailbox #(gpio_transaction) gen2drv;

    // Constructor
    function new(
        virtual gpio_interface vif,
        mailbox #(gpio_transaction) gen2drv
    );
        this.vif     = vif;
        this.gen2drv = gen2drv;
    endfunction

    // Main driver task
    task run();

        gpio_transaction tr;

        forever begin

            // Wait for a transaction from the generator
            gen2drv.get(tr);

            // =====================================================
            // GPIO INPUT STIMULUS
            // =====================================================
            if (tr.is_gpio_stimulus) begin

                // Change GPIO input on the falling edge
                // so the DUT can sample it on the next rising edge
                @(negedge vif.PCLK);

                vif.gpio_in = tr.gpio_value;

                // Give DUT one clock edge to detect the change
                @(posedge vif.PCLK);

            end

            // =====================================================
            // APB TRANSACTION
            // =====================================================
            else begin

                // -------------------------
                // WRITE transaction
                // -------------------------
                if (tr.write) begin

                    // APB setup phase
                    @(negedge vif.PCLK);
                    vif.PSEL    = 1'b1;
                    vif.PENABLE = 1'b0;
                    vif.PWRITE  = 1'b1;
                    vif.PADDR   = tr.addr;
                    vif.PWDATA  = tr.data;

                    // APB access phase
                    @(negedge vif.PCLK);
                    vif.PENABLE = 1'b1;

                    // Wait for transaction completion
                    @(posedge vif.PCLK);
                    while (!vif.PREADY)
                        @(posedge vif.PCLK);

                    // Return bus to idle
                    @(negedge vif.PCLK);
                    vif.PSEL    = 1'b0;
                    vif.PENABLE = 1'b0;
                    vif.PWRITE  = 1'b0;
                    vif.PADDR   = 8'h00;
                    vif.PWDATA  = 32'h00000000;

                end

                // -------------------------
                // READ transaction
                // -------------------------
                else begin

                    // APB setup phase
                    @(negedge vif.PCLK);
                    vif.PSEL    = 1'b1;
                    vif.PENABLE = 1'b0;
                    vif.PWRITE  = 1'b0;
                    vif.PADDR   = tr.addr;
                    vif.PWDATA  = 32'h00000000;

                    // APB access phase
                    @(negedge vif.PCLK);
                    vif.PENABLE = 1'b1;

                    // Wait for transaction completion
                    @(posedge vif.PCLK);
                    while (!vif.PREADY)
                        @(posedge vif.PCLK);

                    // Return bus to idle
                    @(negedge vif.PCLK);
                    vif.PSEL    = 1'b0;
                    vif.PENABLE = 1'b0;
                    vif.PWRITE  = 1'b0;
                    vif.PADDR   = 8'h00;
                    vif.PWDATA  = 32'h00000000;

                end

            end

        end

    endtask

endclass