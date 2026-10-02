# Learning and Debug Notes

This document is the quick engineering notebook for understanding how the project was built and debugged.

## 1. Mental model

Think of the GPIO controller as four boxes:

```text
                 APB / software
                       |
                       v
              +----------------+
              | GPIO registers |
              +----------------+
                |            |
                |            +------------------+
                v                               v
          +-----------+                  +-------------+
          | GPIO I/O  |                  | Interrupt   |
          +-----------+                  | detection   |
                |                       +-------------+
                v                               |
             gpio pin                           v
                                            INT_STATUS
                                                |
                                                v
                                               IRQ
```

A useful one-line memory trick is:

```text
DATA = value
DIR  = direction
TYPE/POLARITY = what counts
ENABLE = permission
STATUS = what happened
CLEAR = erase it
```

## 2. What each class does

### Generator

Creates the story of the test:

```text
"Write DIR"
"Read DIR"
"Write DATA_OUT"
"Read DATA_OUT"
"Configure interrupt"
"Change GPIO input"
"Read status"
"Clear status"
"Read status again"
```

### Driver

Turns that story into electrical-looking bus behavior.

For APB it does:

```text
SETUP -> ACCESS -> WAIT PREADY -> IDLE
```

For GPIO stimulus it does:

```text
set gpio_in on falling edge
        ->
DUT samples on next rising edge
```

### DUT

Actually performs the hardware function.

### Monitor

Watches what really happened on the interface.

### Scoreboard

Asks:

```text
"Did what happened match what should have happened?"
```

## 3. Why mailboxes are present

A mailbox is a queue shared between verification components.

```text
Generator --put--> gen2drv --get--> Driver

Monitor   --put--> mon2scb --get--> Scoreboard
```

This keeps the components decoupled. The generator does not need to know how APB timing works, and the scoreboard does not need to know how the driver created the bus cycle.

## 4. APB in simple terms

APB is a simple peripheral bus. A transfer has two visible phases:

```text
SETUP:
PSEL=1, PENABLE=0

ACCESS:
PSEL=1, PENABLE=1
```

For a write:

```text
PWRITE=1
PADDR = address
PWDATA = data
```

For a read:

```text
PWRITE=0
PADDR = address
PRDATA = result
```

`PREADY` tells the master that the transfer is complete. In this project it is always asserted, so the transfer has no wait-state complexity.

## 5. GPIO direction

With eight pins, `DIR[7:0]` gives one direction bit per pin.

```text
DIR[i] = 1 -> output driver enabled
DIR[i] = 0 -> output driver disabled / input mode
```

When `DIR = FF`, all eight outputs are enabled.

## 6. Interrupt operation

The example uses GPIO0 only to make the waveform easy to follow.

Configuration:

```text
DIR[0]          = 0  input
INT_TYPE[0]     = 1  edge
INT_POLARITY[0] = 1  rising
INT_ENABLE[0]   = 1  enabled
```

Initial condition:

```text
gpio_in[0] = 0
```

Event:

```text
gpio_in[0] = 1
```

Therefore:

```text
0 -> 1 = rising edge
```

The interrupt logic latches the event in `INT_STATUS[0]`, and the enabled pending bit drives the aggregated `irq` output.

Clear:

```text
INT_CLEAR[0] = 1
```

Then the pending status is removed and `irq` falls back to 0.

## 7. Important errors encountered

### Wrong simulation top

The first behavioral run used the RTL top instead of `tb_gpio_controller`.

**Remember:**

```text
RTL top = hardware
TB top  = hardware + stimulus + checking
```

### Sampling race

The scoreboard once reported `DIR` as 0 even though the write was correct.

The problem was not the DUT; the monitor sampled too early in the same simulation time step.

The fix was:

```systemverilog
@(posedge vif.PCLK);
#1;
```

For a more advanced environment, a clocking block is preferable.

### Premature `$finish`

The first test ended before the fourth transaction.

At reset release:

```text
20 ns
```

The test then waited:

```text
#100
```

so simulation ended at:

```text
120 ns
```

The fix was to provide enough runtime and eventually extend the test sequence for interrupt verification.

### Why Zoom Fit matters

The waveform can look empty or uninteresting when you are staring at the wrong time range. The final interrupt event happens much later than the initial DATA/DIR transfers.

Use:

```text
Zoom Fit -> find gpio_in 00 -> 01 -> zoom in
```

## 8. How to study the waveform

Start with these signals:

```text
PCLK
PSEL
PENABLE
PWRITE
PADDR
PWDATA
PRDATA
gpio_in
gpio_out
gpio_oe
irq
```

Read the wave from left to right.

### Basic output example

```text
PADDR=08, PWDATA=FF, PWRITE=1
                |
                v
             DIR=FF
                |
                v
             gpio_oe=FF
```

### Interrupt example

```text
PADDR=0C, PWDATA=01 -> edge mode
PADDR=10, PWDATA=01 -> rising
PADDR=14, PWDATA=01 -> enable

GPIO0: 0 -> 1
       |
       v
INT_STATUS[0] -> 1
       |
       v
IRQ -> 1
       |
INT_CLEAR[0]=1
       |
       v
INT_STATUS[0] -> 0
IRQ -> 0
```

## 9. How to explain the project in a viva

A simple explanation:

> "This project implements an 8-bit GPIO controller with an APB interface. Software accesses GPIO and interrupt registers using memory-mapped APB transactions. The GPIO direction controls whether each pin is driven or treated as an input. The interrupt block can detect configured edge or level conditions, latch them in a sticky status register, and assert an aggregated IRQ signal. The SystemVerilog testbench uses a generator, driver, monitor, and scoreboard connected by mailboxes. The final simulation verifies GPIO read/write operations and a complete rising-edge interrupt lifecycle from configuration to assertion and clearing."

## 10. What not to overclaim

The current evidence proves the final tested sequence. It does not prove every possible interrupt configuration, every GPIO pin, or full APB protocol compliance.

That distinction is important in engineering documentation.
