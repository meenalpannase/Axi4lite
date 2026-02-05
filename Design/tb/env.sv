// ==============================================================================
// File: env.sv
// Description: UVM Environment
// ==============================================================================

class env extends uvm_env;
    
    `uvm_component_utils(env)
    
    // Components
    axi_agent          axi_agt;
    output_monitor     out_mon;
    scoreboard         scb;
    coverage_collector cov;
    
    // Constructor
    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        axi_agt = axi_agent::type_id::create("axi_agt", this);
        out_mon = output_monitor::type_id::create("out_mon", this);
        scb = scoreboard::type_id::create("scb", this);
        cov = coverage_collector::type_id::create("cov", this);
    endfunction
    
    // Connect Phase
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect AXI agent to scoreboard and coverage
        axi_agt.analysis_port.connect(scb.axi_fifo.analysis_export);
        axi_agt.analysis_port.connect(cov.analysis_export);
        
        // Connect output monitor to scoreboard
        out_mon.analysis_port.connect(scb.output_fifo.analysis_export);
    endfunction
    
endclass : env
