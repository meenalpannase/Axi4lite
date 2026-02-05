// ==============================================================================
// File: tb_top.sv
// Description: Top-level Testbench
// ==============================================================================

`timescale 1ns/1ps

module tb_top;
    
    import uvm_pkg::*;
    import tb_pkg::*;
    `include "uvm_macros.svh"
    
    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Clock Generation (100 MHz -> 10ns period)
    initial begin
        clk = 0;
        forever #5ns clk = ~clk;
    end
    
    // Interface Instance
    axi_if axi_vif(clk, rst_n);
    
    // DUT Instance
    axi_ledseg_irq #(
        .ADDRESS(32),
        .DATA_WIDTH(32)
    ) dut (
        .ACLK(axi_vif.clk),
        .ARESETn(axi_vif.rst_n),
        
        // Write Address Channel
        .S_AWADDR(axi_vif.awaddr),
        .S_AWVALID(axi_vif.awvalid),
        .S_AWREADY(axi_vif.awready),
        
        // Write Data Channel
        .S_WDATA(axi_vif.wdata),
        .S_WSTRB(axi_vif.wstrb),
        .S_WVALID(axi_vif.wvalid),
        .S_WREADY(axi_vif.wready),
        
        // Write Response Channel
        .S_BREADY(axi_vif.bready),
        .S_BVALID(axi_vif.bvalid),
        .S_BRESP(axi_vif.bresp),
        
        // Read Address Channel
        .S_ARADDR(axi_vif.araddr),
        .S_ARVALID(axi_vif.arvalid),
        .S_ARREADY(axi_vif.arready),
        
        // Read Data Channel
        .S_RREADY(axi_vif.rready),
        .S_RDATA(axi_vif.rdata),
        .S_RVALID(axi_vif.rvalid),
        .S_RRESP(axi_vif.rresp),
        
        // External Outputs
        .LED_OUT(axi_vif.led_out),
        .SEVENSEG_OUT(axi_vif.sevenseg_out),
        .IRQ_OUT(axi_vif.irq_out)
    );
    
    // Initial Block
    initial begin
        // Set interface in config DB
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_vif);
        
        // Set verbosity
        uvm_top.set_report_verbosity_level_hier(UVM_MEDIUM);
        
        // Enable dumping
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
        
        // Run test
        run_test();
    end
    
    // Timeout watchdog
    initial begin
        #1000us;
        `uvm_fatal("TIMEOUT", "Simulation timeout - 1ms exceeded")
    end
    
    // Reset generation (can be overridden by test)
    initial begin
        rst_n = 1'b0;
    end
    
endmodule : tb_top
