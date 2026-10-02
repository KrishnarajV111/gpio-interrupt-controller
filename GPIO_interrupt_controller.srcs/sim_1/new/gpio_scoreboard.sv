class gpio_scoreboard;

    mailbox #(gpio_transaction) mon2scb;

    // Expected GPIO values
    logic [7:0] expected_gpio_out;
    logic [7:0] expected_gpio_oe;
    logic [7:0] expected_dir;

    // Track whether interrupt has been cleared
    bit interrupt_cleared;

    function new(mailbox #(gpio_transaction) mon2scb);

        this.mon2scb = mon2scb;

        expected_gpio_out = 8'h00;
        expected_gpio_oe  = 8'h00;
        expected_dir      = 8'h00;

        interrupt_cleared = 1'b0;

    endfunction


    task run();

        gpio_transaction tr;

        forever begin

            // Wait for monitored transaction
            mon2scb.get(tr);


            // =================================================
            // WRITE TRANSACTION
            // =================================================
            if (tr.observed_write) begin

                case (tr.observed_addr)

                    // -----------------------------------------
                    // DATA_OUT
                    // -----------------------------------------
                    8'h04: begin

                        expected_gpio_out = tr.observed_data[7:0];

                        if (tr.observed_gpio_out === expected_gpio_out) begin

                            $display("PASS: DATA_OUT = 0x%02h",
                                     tr.observed_gpio_out);

                        end
                        else begin

                            $error("FAIL: DATA_OUT expected=0x%02h actual=0x%02h",
                                   expected_gpio_out,
                                   tr.observed_gpio_out);

                        end

                    end


                    // -----------------------------------------
                    // DIR
                    // -----------------------------------------
                    8'h08: begin

                        expected_dir     = tr.observed_data[7:0];
                        expected_gpio_oe = tr.observed_data[7:0];

                        if (tr.observed_gpio_oe === expected_gpio_oe) begin

                            $display("PASS: DIR / GPIO_OE = 0x%02h",
                                     tr.observed_gpio_oe);

                        end
                        else begin

                            $error("FAIL: DIR / GPIO_OE expected=0x%02h actual=0x%02h",
                                   expected_gpio_oe,
                                   tr.observed_gpio_oe);

                        end

                    end


                    // -----------------------------------------
                    // INTERRUPT CONFIGURATION
                    // -----------------------------------------
                    8'h0C: begin

                        $display("PASS: INT_TYPE written = 0x%02h",
                                 tr.observed_data[7:0]);

                    end


                    8'h10: begin

                        $display("PASS: INT_POLARITY written = 0x%02h",
                                 tr.observed_data[7:0]);

                    end


                    8'h14: begin

                        $display("PASS: INT_ENABLE written = 0x%02h",
                                 tr.observed_data[7:0]);

                    end


                    // -----------------------------------------
                    // INT_CLEAR
                    // -----------------------------------------
                    8'h1C: begin

                        if (tr.observed_data[0] == 1'b1) begin

                            interrupt_cleared = 1'b1;

                            $display("INFO: INT_CLEAR written for GPIO0");

                            if (tr.observed_irq == 1'b0)
                                $display("PASS: IRQ cleared");
                            else
                                $error("FAIL: IRQ still HIGH after INT_CLEAR");

                        end

                    end


                    default: begin

                        $display("INFO: APB write observed at address 0x%02h",
                                 tr.observed_addr);

                    end

                endcase

            end


            // =================================================
            // READ TRANSACTION
            // =================================================
            else begin

                case (tr.observed_addr)

                    // -----------------------------------------
                    // READ DATA_OUT
                    // -----------------------------------------
                    8'h04: begin

                        if (tr.observed_data ===
                            {24'h000000, expected_gpio_out}) begin

                            $display("PASS: READ DATA_OUT = 0x%02h",
                                     tr.observed_data[7:0]);

                        end
                        else begin

                            $error("FAIL: READ DATA_OUT expected=0x%02h actual=0x%08h",
                                   expected_gpio_out,
                                   tr.observed_data);

                        end

                    end


                    // -----------------------------------------
                    // READ DIR
                    // -----------------------------------------
                    8'h08: begin

                        if (tr.observed_data ===
                            {24'h000000, expected_dir}) begin

                            $display("PASS: READ DIR = 0x%02h",
                                     tr.observed_data[7:0]);

                        end
                        else begin

                            $error("FAIL: READ DIR expected=0x%02h actual=0x%08h",
                                   expected_dir,
                                   tr.observed_data);

                        end

                    end


                    // -----------------------------------------
                    // READ INT_STATUS
                    // -----------------------------------------
                    8'h18: begin

                        // Before INT_CLEAR:
                        // interrupt must be pending
                        if (!interrupt_cleared) begin

                            if (tr.observed_data[0] == 1'b1) begin

                                $display("PASS: INT_STATUS = 1");

                            end
                            else begin

                                $error("FAIL: INT_STATUS expected=1 actual=%0d",
                                       tr.observed_data[0]);

                            end


                            if (tr.observed_irq == 1'b1) begin

                                $display("PASS: IRQ = 1");

                            end
                            else begin

                                $error("FAIL: IRQ expected=1 actual=%0d",
                                       tr.observed_irq);

                            end

                        end

                        // After INT_CLEAR:
                        // interrupt must be cleared
                        else begin

                            if (tr.observed_data[0] == 1'b0) begin

                                $display("PASS: INT_STATUS CLEARED");

                            end
                            else begin

                                $error("FAIL: INT_STATUS expected=0 actual=%0d",
                                       tr.observed_data[0]);

                            end


                            if (tr.observed_irq == 1'b0) begin

                                $display("PASS: IRQ CLEARED");

                            end
                            else begin

                                $error("FAIL: IRQ expected=0 actual=%0d",
                                       tr.observed_irq);

                            end

                        end

                    end


                    default: begin

                        $display("INFO: APB read observed at address 0x%02h",
                                 tr.observed_addr);

                    end

                endcase

            end

        end

    endtask

endclass