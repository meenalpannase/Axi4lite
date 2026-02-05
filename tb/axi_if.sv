// ==============================================================================
// File: axi_if.sv
// Description: AXI4-Lite Interface
// ==============================================================================

interface axi_if(input logic clk, input logic rst_n);
    
    // Write Address Channel
    logic [31:0]  awaddr;
    logic         awvalid;
    logic         awready;
    
    // Write Data Channel
    logic [31:0]  wdata;
    logic [3:0]   wstrb;
    logic         wvalid;
    logic         wready;
    
    // Write Response Channel
    logic         bready;
    logic         bvalid;
    logic [1:0]   bresp;
    
    // Read Address Channel
    logic [31:0]  araddr;
    logic         arvalid;
    logic         arready;
    
    // Read Data Channel
    logic         rready;
    logic [31:0]  rdata;
    logic         rvalid;
    logic [1:0]   rresp;
    
    // External Outputs
    logic [7:0]   led_out;
    logic [7:0]   sevenseg_out;
    logic         irq_out;
    
    // Master Clocking Block
    clocking master_cb @(posedge clk);
        default input #1ns output #1ns;
        
        // Write Address Channel
        output awaddr;
        output awvalid;
        input  awready;
        
        // Write Data Channel
        output wdata;
        output wstrb;
        output wvalid;
        input  wready;
        
        // Write Response Channel
        output bready;
        input  bvalid;
        input  bresp;
        
        // Read Address Channel
        output araddr;
        output arvalid;
        input  arready;
        
        // Read Data Channel
        output rready;
        input  rdata;
        input  rvalid;
        input  rresp;
    endclocking
    
    // Monitor Clocking Block
    clocking monitor_cb @(posedge clk);
        default input #1ns output #1ns;
        
        // Write Address Channel
        input awaddr;
        input awvalid;
        input awready;
        
        // Write Data Channel
        input wdata;
        input wstrb;
        input wvalid;
        input wready;
        
        // Write Response Channel
        input bready;
        input bvalid;
        input bresp;
        
        // Read Address Channel
        input araddr;
        input arvalid;
        input arready;
        
        // Read Data Channel
        input rready;
        input rdata;
        input rvalid;
        input rresp;
        
        // External Outputs
        input led_out;
        input sevenseg_out;
        input irq_out;
    endclocking
    
    // Master Modport
    modport master_mp(
        clocking master_cb,
        input clk,
        input rst_n
    );
    
    // Monitor Modport
    modport monitor_mp(
        clocking monitor_cb,
        input clk,
        input rst_n
    );
    
    // DUT Modport
    modport dut_mp(
        input  clk,
        input  rst_n,
        
        input  awaddr,
        input  awvalid,
        output awready,
        
        input  wdata,
        input  wstrb,
        input  wvalid,
        output wready,
        
        input  bready,
        output bvalid,
        output bresp,
        
        input  araddr,
        input  arvalid,
        output arready,
        
        input  rready,
        output rdata,
        output rvalid,
        output rresp,
        
        output led_out,
        output sevenseg_out,
        output irq_out
    );
    
    // Assertions for Protocol Checking
    
    // Write Address Channel
    property p_awvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (awvalid && !awready) |=> $stable(awvalid) && $stable(awaddr);
    endproperty
    assert_awvalid_stable: assert property(p_awvalid_stable)
        else `uvm_error("AXI_IF", "AWVALID/AWADDR changed before AWREADY")
    
    // Write Data Channel
    property p_wvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (wvalid && !wready) |=> $stable(wvalid) && $stable(wdata) && $stable(wstrb);
    endproperty
    assert_wvalid_stable: assert property(p_wvalid_stable)
        else `uvm_error("AXI_IF", "WVALID/WDATA/WSTRB changed before WREADY")
    
    // Read Address Channel
    property p_arvalid_stable;
        @(posedge clk) disable iff (!rst_n)
        (arvalid && !arready) |=> $stable(arvalid) && $stable(araddr);
    endproperty
    assert_arvalid_stable: assert property(p_arvalid_stable)
        else `uvm_error("AXI_IF", "ARVALID/ARADDR changed before ARREADY")
    
    // BVALID must remain asserted until BREADY
    property p_bvalid_until_bready;
        @(posedge clk) disable iff (!rst_n)
        (bvalid && !bready) |=> bvalid;
    endproperty
    assert_bvalid_until_bready: assert property(p_bvalid_until_bready)
        else `uvm_error("AXI_IF", "BVALID deasserted before BREADY")
    
    // RVALID must remain asserted until RREADY
    property p_rvalid_until_rready;
        @(posedge clk) disable iff (!rst_n)
        (rvalid && !rready) |=> rvalid;
    endproperty
    assert_rvalid_until_rready: assert property(p_rvalid_until_rready)
        else `uvm_error("AXI_IF", "RVALID deasserted before RREADY")
    
endinterface : axi_if
