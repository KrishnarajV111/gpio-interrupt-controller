`timescale 1ns/1ps

module tb_gpio_controller;

    gpio_interface #(.NUM_PINS(8)) vif();

    gpio_controller #(.NUM_PINS(8)) dut (
        .PCLK       (vif.PCLK),
        .PRESETn    (vif.PRESETn),
        .PSEL       (vif.PSEL),
        .PENABLE    (vif.PENABLE),
        .PWRITE     (vif.PWRITE),
        .PADDR      (vif.PADDR),
        .PWDATA     (vif.PWDATA),
        .PRDATA     (vif.PRDATA),
        .PREADY     (vif.PREADY),
        .PSLVERR    (vif.PSLVERR),
        .gpio_in    (vif.gpio_in),
        .gpio_out   (vif.gpio_out),
        .gpio_oe    (vif.gpio_oe),
        .irq        (vif.irq)
    );

    // Clock
    initial vif.PCLK = 0;
    always #5 vif.PCLK = ~vif.PCLK;

    // ---------------- APB WRITE ----------------
    task apb_write(input [7:0] addr, input [31:0] data);

        @(negedge vif.PCLK);
        vif.PSEL    = 1;
        vif.PENABLE = 0;
        vif.PWRITE  = 1;
        vif.PADDR   = addr;
        vif.PWDATA  = data;

        @(negedge vif.PCLK);
        vif.PENABLE = 1;

        @(posedge vif.PCLK);

        while (!vif.PREADY)
            @(posedge vif.PCLK);

        @(negedge vif.PCLK);
        vif.PSEL    = 0;
        vif.PENABLE = 0;

    endtask

    // ---------------- APB READ ----------------
    task apb_read(
        input  [7:0] addr,
        output [31:0] data
    );

        @(negedge vif.PCLK);
        vif.PSEL    = 1;
        vif.PENABLE = 0;
        vif.PWRITE  = 0;
        vif.PADDR   = addr;
        vif.PWDATA  = 0;

        @(negedge vif.PCLK);
        vif.PENABLE = 1;

        @(posedge vif.PCLK);

        while (!vif.PREADY)
            @(posedge vif.PCLK);

        #1;
        data = vif.PRDATA;

        @(negedge vif.PCLK);
        vif.PSEL    = 0;
        vif.PENABLE = 0;

    endtask

    reg [31:0] read_data;

    // ---------------- TEST ----------------
    initial begin

        // Initial values
        vif.PRESETn = 0;
        vif.PSEL    = 0;
        vif.PENABLE = 0;
        vif.PWRITE  = 0;
        vif.PADDR   = 0;
        vif.PWDATA  = 0;
        vif.gpio_in = 8'h00;

        #20;
        vif.PRESETn = 1;

        // =================================================
        // 1. GPIO BASIC TEST
        // =================================================

        apb_write(8'h08, 32'h000000FF);   // DIR = output

        apb_read(8'h08, read_data);

        if (read_data == 32'h000000FF)
            $display("PASS: READ DIR = 0x%08h", read_data);
        else
            $error("FAIL: READ DIR = 0x%08h", read_data);

        apb_write(8'h04, 32'h000000A5);   // DATA_OUT

        apb_read(8'h04, read_data);

        if (read_data == 32'h000000A5)
            $display("PASS: READ DATA_OUT = 0x%08h", read_data);
        else
            $error("FAIL: READ DATA_OUT = 0x%08h", read_data);

        // =================================================
        // 2. INTERRUPT CONFIGURATION
        // =================================================

        // Make GPIO0 an input
        apb_write(8'h08, 32'h00000000);

        // Edge interrupt
        apb_write(8'h0C, 32'h00000001);

        // Rising edge
        apb_write(8'h10, 32'h00000001);

        // Enable GPIO0 interrupt
        apb_write(8'h14, 32'h00000001);

        $display("INFO: Interrupt configured");

        // =================================================
        // 3. GENERATE RISING EDGE
        // =================================================

        vif.gpio_in = 8'h00;
        @(posedge vif.PCLK);

        vif.gpio_in = 8'h01;
        @(posedge vif.PCLK);

        #1;

        // =================================================
        // 4. CHECK STATUS + IRQ
        // =================================================

        apb_read(8'h18, read_data);

        if (read_data[0] == 1'b1)
            $display("PASS: INT_STATUS = 1");
        else
            $error("FAIL: INT_STATUS = 0");

        if (vif.irq == 1'b1)
            $display("PASS: IRQ = 1");
        else
            $error("FAIL: IRQ = 0");

        // =================================================
        // 5. CLEAR INTERRUPT
        // =================================================

        apb_write(8'h1C, 32'h00000001);

        @(posedge vif.PCLK);
        #1;

        apb_read(8'h18, read_data);

        if (read_data[0] == 1'b0)
            $display("PASS: INT_STATUS CLEARED");
        else
            $error("FAIL: INT_STATUS NOT CLEARED");

        if (vif.irq == 1'b0)
            $display("PASS: IRQ CLEARED");
        else
            $error("FAIL: IRQ STILL HIGH");

        $display("======================================");
        $display(" GPIO INTERRUPT TEST COMPLETE");
        $display("======================================");

        #20;
        $finish;

    end

endmodule