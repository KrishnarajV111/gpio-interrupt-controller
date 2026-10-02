class gpio_generator;

    // Mailbox from generator to driver
    mailbox #(gpio_transaction) gen2drv;

    // Constructor
    function new(mailbox #(gpio_transaction) gen2drv);
        this.gen2drv = gen2drv;
    endfunction

    // Main generator task
    task run();

        gpio_transaction tr;

        // =====================================================
        // BASIC GPIO TESTS
        // =====================================================

        // TRANSACTION 1: WRITE DIR = FF
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h08;
        tr.data  = 32'h000000FF;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

        // TRANSACTION 2: READ DIR
        tr = new();
        tr.write = 1'b0;
        tr.addr  = 8'h08;
        tr.data  = 32'h00000000;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

        // TRANSACTION 3: WRITE DATA_OUT = A5
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h04;
        tr.data  = 32'h000000A5;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

        // TRANSACTION 4: READ DATA_OUT
        tr = new();
        tr.write = 1'b0;
        tr.addr  = 8'h04;
        tr.data  = 32'h00000000;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);


        // =====================================================
        // INTERRUPT TEST
        // =====================================================

        // TRANSACTION 5: CONFIGURE GPIO AS INPUT
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h08;
        tr.data  = 32'h00000000;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

        // TRANSACTION 6: SELECT EDGE INTERRUPT
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h0C;
        tr.data  = 32'h00000001;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

        // TRANSACTION 7: SELECT RISING EDGE
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h10;
        tr.data  = 32'h00000001;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

        // TRANSACTION 8: ENABLE INTERRUPT FOR GPIO0
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h14;
        tr.data  = 32'h00000001;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);


        // =====================================================
        // GPIO EVENT
        // =====================================================

        // TRANSACTION 9: GPIO0 LOW -> HIGH
        tr = new();
        tr.is_gpio_stimulus = 1'b1;
        tr.gpio_value = 8'h01;
        tr.display();
        gen2drv.put(tr);


        // =====================================================
        // CHECK INTERRUPT STATUS
        // =====================================================

        // TRANSACTION 10: READ INT_STATUS
        tr = new();
        tr.write = 1'b0;
        tr.addr  = 8'h18;
        tr.data  = 32'h00000000;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);


        // =====================================================
        // CLEAR INTERRUPT
        // =====================================================

        // TRANSACTION 11: CLEAR GPIO0 INTERRUPT
        tr = new();
        tr.write = 1'b1;
        tr.addr  = 8'h1C;
        tr.data  = 32'h00000001;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);


        // =====================================================
        // VERIFY CLEAR
        // =====================================================

        // TRANSACTION 12: READ INT_STATUS AGAIN
        tr = new();
        tr.write = 1'b0;
        tr.addr  = 8'h18;
        tr.data  = 32'h00000000;
        tr.is_gpio_stimulus = 1'b0;
        tr.display();
        gen2drv.put(tr);

    endtask

endclass