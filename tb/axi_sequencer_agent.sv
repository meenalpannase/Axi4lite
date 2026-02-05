// ==============================================================================
// File: axi_sequencer.sv
// Description: AXI4-Lite Sequencer
// ==============================================================================

class axi_sequencer extends uvm_sequencer #(axi_transaction);
    
    `uvm_component_utils(axi_sequencer)
    
    function new(string name = "axi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
endclass : axi_sequencer


// ==============================================================================
// File: axi_agent.sv
// Description: AXI4-Lite Agent
// ==============================================================================

class axi_agent extends uvm_agent;
    
    `uvm_component_utils(axi_agent)
    
    // Components
    axi_driver    driver;
    axi_monitor   monitor;
    axi_sequencer sequencer;
    
    // Analysis Port
    uvm_analysis_port #(axi_transaction) analysis_port;
    
    // Constructor
    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        monitor = axi_monitor::type_id::create("monitor", this);
        
        if (is_active == UVM_ACTIVE) begin
            driver = axi_driver::type_id::create("driver", this);
            sequencer = axi_sequencer::type_id::create("sequencer", this);
        end
    endfunction
    
    // Connect Phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        analysis_port = monitor.analysis_port;
        
        if (is_active == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
    
endclass : axi_agent
