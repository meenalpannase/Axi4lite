# AXI4-Lite LED/Seven-Segment/IRQ Controller - UVM Testbench

## Overview

This is a complete UVM-based verification environment for the AXI4-Lite LED/Seven-Segment/IRQ controller peripheral. The testbench provides comprehensive verification coverage including protocol compliance, functional testing, and stress testing.

## Design Under Test (DUT)

**Module:** `axi_ledseg_irq`

**Features:**
- AXI4-Lite slave interface
- 8-bit LED output control (Register 0x00)
- 8-bit seven-segment display control (Register 0x04)
- Interrupt status register with W1C support (Register 0x08)
- Edge-triggered IRQ generation when LED transitions to 0xFF
- Independent read and write channels
- Byte-level write support via WSTRB

## Directory Structure

```
.
├── axi_if.sv                   # AXI4-Lite interface with protocol assertions
├── axi_transaction.sv          # Transaction class
├── axi_driver.sv               # AXI4-Lite master driver
├── axi_monitor.sv              # AXI4-Lite monitor
├── axi_sequencer_agent.sv      # Sequencer and agent
├── output_monitor.sv           # Output signals monitor
├── scoreboard.sv               # Scoreboard with reference model
├── coverage.sv                 # Functional coverage collector
├── env.sv                      # UVM environment
├── sequences.sv                # Test sequences
├── tests.sv                    # Test cases
├── tb_pkg.sv                   # Testbench package
├── tb_top.sv                   # Top-level testbench
├── Makefile                    # Compilation and simulation scripts
├── test_plan.md                # Detailed test plan
└── rtl/
    └── axi_ledseg_irq.sv       # DUT RTL (place your design here)
```

## Prerequisites

### Required Tools
- SystemVerilog simulator with UVM support:
  - Synopsys VCS (recommended)
  - Mentor Questa/ModelSim
  - Cadence Xcelium
- UVM 1.2 library
- Make utility

### Environment Setup

For VCS:
```bash
export VCS_HOME=/path/to/vcs
export UVM_HOME=$VCS_HOME/etc/uvm-1.2
```

For Questa:
```bash
export QUESTA_HOME=/path/to/questa
export QUESTA_UVM_HOME=$QUESTA_HOME/uvm-1.2
```

For Xcelium:
```bash
export XCELIUM_HOME=/path/to/xcelium
export XCELIUM_UVM_HOME=$XCELIUM_HOME/tools/uvm-1.2
```

## Quick Start

### 1. Setup

Place your DUT RTL file in the `rtl/` directory:
```bash
mkdir -p rtl
cp /path/to/axi_ledseg_irq.sv rtl/
```

### 2. Compile

```bash
# Using default simulator (VCS)
make compile

# Or specify simulator
make compile SIM=QUESTA
make compile SIM=XCELIUM
```

### 3. Run Individual Tests

```bash
# Run reset test
make run_reset

# Run basic read/write test
make run_basic

# Run WSTRB test
make run_wstrb

# Run IRQ test
make run_irq

# Run concurrent operations test
make run_concurrent

# Run stress test
make run_stress
```

### 4. Run Full Regression

```bash
make run_regression
```

### 5. Run with Custom Options

```bash
# Specify test name
make sim TEST=irq_test

# Specify random seed
make sim TEST=stress_test SEED=12345

# Specify UVM verbosity
make sim TEST=regression_test UVM_VERBOSITY=UVM_HIGH

# Change simulator
make sim SIM=QUESTA TEST=reset_test
```

## Test Suite

### Sanity Tests
- **TEST-001: reset_test** - Verifies reset behavior
- **TEST-002: basic_write_test** - Basic write operations
- **TEST-003: basic_read_test** - Basic read operations

### Protocol Tests
- **TEST-004-008: protocol_test** - AXI4-Lite protocol compliance

### Register Tests
- **TEST-009-011: register_test** - Register read/write functionality
- **TEST-012: wstrb_test** - Byte-enable (WSTRB) testing

### Interrupt Tests
- **TEST-013-017: irq_test** - IRQ generation, clearing, and edge detection

### Concurrent Operations
- **TEST-018-021: concurrent_test** - Simultaneous read/write operations

### Stress Tests
- **TEST-026: stress_test** - Random stress testing

### Full Regression
- **regression_test** - Runs all tests sequentially

## Coverage

The testbench includes comprehensive functional coverage:

1. **Register Access Coverage**
   - All register addresses
   - Read and write operations
   - Cross coverage of address and access type

2. **WSTRB Coverage**
   - All byte-enable combinations
   - Per-register WSTRB patterns

3. **LED Pattern Coverage**
   - Common LED patterns (all on/off, alternating, etc.)
   - IRQ trigger condition (0xFF)

4. **Seven-Segment Coverage**
   - Digit encodings (0-9)
   - Custom patterns

5. **IRQ Coverage**
   - IRQ assertion and deassertion
   - Trigger conditions
   - Clear operations

6. **Response Coverage**
   - All AXI response types
   - Per-transaction-type responses

### Viewing Coverage

For VCS:
```bash
make cov
# Open coverage report: firefox sim/coverage/index.html
```

For Questa:
```bash
make cov
# Open coverage report: firefox sim/coverage/index.html
```

## Scoreboard and Checking

The testbench includes a self-checking scoreboard with:

- **Reference Model**: Maintains expected register states
- **Automatic Checking**: Compares DUT outputs with expected values
- **IRQ Logic Checking**: Verifies correct IRQ generation and clearing
- **WSTRB Logic**: Validates byte-enable operations
- **Response Checking**: Ensures BRESP and RRESP are always OKAY

### Checking Results

Check the simulation log for:
- `CHECK PASSED`: Successful verification
- `CHECK FAILED`: Verification mismatch (ERROR)
- Final scoreboard report with pass/fail statistics

## Debugging

### Waveform Viewing

The testbench automatically generates VCD dump files:
```bash
# View waveforms with GTKWave
gtkwave dump.vcd

# Or with your simulator's waveform viewer
dve -vpd dump.vpd  # For VCS
vsim -view vsim.wlf  # For Questa
```

### Increasing Verbosity

```bash
# Run with high verbosity
make sim TEST=irq_test UVM_VERBOSITY=UVM_HIGH

# Or full debug
make sim TEST=stress_test UVM_VERBOSITY=UVM_DEBUG
```

### Common Issues

1. **"Virtual interface not found"**
   - Ensure `tb_top.sv` correctly sets the interface in config DB
   - Check interface is properly connected to DUT

2. **"Timeout"**
   - Increase timeout in `tb_top.sv`
   - Check for deadlocks in sequences
   - Verify DUT is responding to transactions

3. **"Compilation errors"**
   - Verify all file paths in Makefile
   - Check UVM installation
   - Ensure DUT file exists in rtl/ directory

## Customization

### Adding New Tests

1. Create new sequence in `sequences.sv`:
```systemverilog
class my_sequence extends base_sequence;
    `uvm_object_utils(my_sequence)
    
    virtual task body();
        // Your test logic
    endtask
endclass
```

2. Create new test in `tests.sv`:
```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)
    
    virtual task run_phase(uvm_phase phase);
        my_sequence seq;
        phase.raise_objection(this);
        apply_reset();
        seq = my_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        phase.drop_objection(this);
    endtask
endclass
```

3. Run your test:
```bash
make sim TEST=my_test
```

### Modifying Coverage

Edit `coverage.sv` to add new coverage groups or modify existing ones.

### Adjusting Timing

Edit delays in sequences or modify clock period in `tb_top.sv`.

## Test Results

After running tests, check:

1. **Simulation Log**: `sim_<testname>.log`
   - Contains all UVM messages
   - Shows test PASS/FAIL status
   - Reports errors and warnings

2. **Coverage Report**: `sim/coverage/`
   - Functional coverage metrics
   - Code coverage analysis

3. **Waveforms**: `dump.vcd` or `dump.vpd`
   - Signal-level debugging

## Performance

Typical simulation times (on modern workstation):
- Individual test: 0.5 - 2 seconds
- Stress test: 5 - 10 seconds
- Full regression: 15 - 30 seconds

## Support and Contact

For questions or issues:
1. Check test_plan.md for detailed test descriptions
2. Review UVM 1.2 User Guide
3. Consult AXI4-Lite specification document

## License

This testbench is provided as-is for educational and verification purposes.

## Version History

- **v1.0** (February 2026) - Initial release
  - Complete UVM environment
  - 28 test cases
  - Full functional coverage
  - Protocol assertions
  - Self-checking scoreboard

---

**Happy Verifying! 🚀**
