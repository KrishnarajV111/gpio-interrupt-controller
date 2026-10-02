class gpio_monitor;

    // Interface used to observe the DUT
    virtual gpio_interface vif;

    // Mailbox from monitor to scoreboard
    mailbox #(gpio_transaction) mon2scb;

    // Constructor
    function new(
        virtual gpio_interface vif,
        mailbox #(gpio_transaction) mon2scb
    );
        this.vif     = vif;
        this.mon2scb = mon2scb;
    endfunction

    // Monitor task
    task run();

        gpio_transaction tr;

        forever begin

            // Wait for APB access
            @(posedge vif.PCLK);
            #1;
            if (vif.PSEL && vif.PENABLE) begin

                tr = new();

                // Capture APB transaction
                tr.observed_write = vif.PWRITE;
                tr.observed_addr  = vif.PADDR;
                tr.observed_data  = vif.PWRITE ?
                                    vif.PWDATA : vif.PRDATA;

                // Capture GPIO outputs
                tr.observed_gpio_out = vif.gpio_out;
                tr.observed_gpio_oe  = vif.gpio_oe;

                // Capture interrupt
                tr.observed_irq = vif.irq;

                // Send to scoreboard
                mon2scb.put(tr);

            end

        end

    endtask

endclass