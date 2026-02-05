// ==============================================================================
// File: axi_monitor.sv
// Description: AXI4-Lite Monitor
// ==============================================================================

class axi_monitor extends uvm_monitor;
    
    `uvm_component_utils(axi_monitor)
    
    // Virtual Interface
    virtual axi_if vif;
    
    // Analysis Port
    uvm_analysis_port #(axi_transaction) analysis_port;
    
    // Constructor
    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
        
        analysis_port = new("analysis_port", this);
    endfunction
    
    // Run Phase
    virtual task run_phase(uvm_phase phase);
        fork
            monitor_write();
            monitor_read();
        join_none
    endtask
    
    // Monitor Write Transactions
    virtual task monitor_write();
        axi_transaction trans;
        bit [31:0] addr;
        bit [31:0] data;
        bit [3:0]  strb;
        bit [1:0]  resp;
        
        forever begin
            @(vif.monitor_cb);
            
            // Detect write address handshake
            if (vif.monitor_cb.awvalid && vif.monitor_cb.awready) begin
                addr = vif.monitor_cb.awaddr;
                
                // Wait for write data handshake
                fork
                    begin
                        while (!(vif.monitor_cb.wvalid && vif.monitor_cb.wready)) begin
                            @(vif.monitor_cb);
                        end
                        data = vif.monitor_cb.wdata;
                        strb = vif.monitor_cb.wstrb;
                    end
                    begin
                        repeat(100) @(vif.monitor_cb);
                        `uvm_warning(get_type_name(), "Timeout waiting for WVALID/WREADY")
                    end
                join_any
                disable fork;
                
                // Wait for write response
                fork
                    begin
                        while (!(vif.monitor_cb.bvalid && vif.monitor_cb.bready)) begin
                            @(vif.monitor_cb);
                        end
                        resp = vif.monitor_cb.bresp;
                    end
                    begin
                        repeat(100) @(vif.monitor_cb);
                        `uvm_warning(get_type_name(), "Timeout waiting for BVALID/BREADY")
                    end
                join_any
                disable fork;
                
                // Create transaction
                trans = axi_transaction::type_id::create("trans");
                trans.trans_type = axi_transaction::WRITE;
                trans.addr = addr;
                trans.data = data;
                trans.strb = strb;
                trans.resp = axi_transaction::resp_type_e'(resp);
                
                `uvm_info(get_type_name(), 
                         $sformatf("Monitored Write:\n%s", trans.convert2string()), 
                         UVM_HIGH)
                
                // Send to analysis port
                analysis_port.write(trans);
            end
        end
    endtask
    
    // Monitor Read Transactions
    virtual task monitor_read();
        axi_transaction trans;
        bit [31:0] addr;
        bit [31:0] data;
        bit [1:0]  resp;
        
        forever begin
            @(vif.monitor_cb);
            
            // Detect read address handshake
            if (vif.monitor_cb.arvalid && vif.monitor_cb.arready) begin
                addr = vif.monitor_cb.araddr;
                
                // Wait for read data handshake
                fork
                    begin
                        while (!(vif.monitor_cb.rvalid && vif.monitor_cb.rready)) begin
                            @(vif.monitor_cb);
                        end
                        data = vif.monitor_cb.rdata;
                        resp = vif.monitor_cb.rresp;
                    end
                    begin
                        repeat(100) @(vif.monitor_cb);
                        `uvm_warning(get_type_name(), "Timeout waiting for RVALID/RREADY")
                    end
                join_any
                disable fork;
                
                // Create transaction
                trans = axi_transaction::type_id::create("trans");
                trans.trans_type = axi_transaction::READ;
                trans.addr = addr;
                trans.read_data = data;
                trans.resp = axi_transaction::resp_type_e'(resp);
                
                `uvm_info(get_type_name(), 
                         $sformatf("Monitored Read:\n%s", trans.convert2string()), 
                         UVM_HIGH)
                
                // Send to analysis port
                analysis_port.write(trans);
            end
        end
    endtask
    
endclass : axi_monitor
