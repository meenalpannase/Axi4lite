// ==============================================================================
// File: tb_pkg.sv
// Description: Testbench Package
// ==============================================================================

package tb_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Include all testbench files
    `include "axi_transaction.sv"
    `include "axi_driver.sv"
    `include "axi_monitor.sv"
    `include "axi_sequencer_agent.sv"
    `include "output_monitor.sv"
    `include "scoreboard.sv"
    `include "coverage.sv"
    `include "env.sv"
    `include "sequences.sv"
    `include "tests.sv"
    
endpackage : tb_pkg
