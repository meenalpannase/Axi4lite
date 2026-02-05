// ==============================================================================
// File: axi_driver.sv
// Description: AXI4-Lite Master Driver
// ==============================================================================

class axi_driver extends uvm_driver #(axi_transaction);
    
    `uvm_component_utils(axi_driver)
    
    // Virtual Interface
    virtual axi_if vif;
    
    // Constructor
    function new(string name = "axi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found in config DB")
    endfunction
    
    // Run Phase
    virtual task run_phase(uvm_phase phase);
        fork
            reset_signals();
            drive_transactions();
        join_none
    endtask
    
    // Reset Handler
    virtual task reset_signals();
        forever begin
            @(negedge vif.rst_n);
            `uvm_info(get_type_name(), "Reset detected - resetting all signals", UVM_MEDIUM)
            
            vif.master_cb.awaddr  <= 32'h0;
            vif.master_cb.awvalid <= 1'b0;
            vif.master_cb.wdata   <= 32'h0;
            vif.master_cb.wstrb   <= 4'h0;
            vif.master_cb.wvalid  <= 1'b0;
            vif.master_cb.bready  <= 1'b0;
            vif.master_cb.araddr  <= 32'h0;
            vif.master_cb.arvalid <= 1'b0;
            vif.master_cb.rready  <= 1'b0;
        end
    endtask
    
    // Main Driver Loop
    virtual task drive_transactions();
        forever begin
            @(posedge vif.rst_n);
            `uvm_info(get_type_name(), "Reset deasserted - ready to drive", UVM_MEDIUM)
            
            forever begin
                // Get next transaction from sequencer
                seq_item_port.get_next_item(req);
                
                `uvm_info(get_type_name(), 
                         $sformatf("Driving transaction:\n%s", req.convert2string()), 
                         UVM_HIGH)
                
                // Drive based on transaction type
                if (req.trans_type == axi_transaction::WRITE) begin
                    drive_write(req);
                end else begin
                    drive_read(req);
                end
                
                // Signal completion
                seq_item_port.item_done();
            end
        end
    endtask
    
    // Drive Write Transaction
    virtual task drive_write(axi_transaction trans);
        fork
            drive_write_addr(trans);
            drive_write_data(trans);
        join
        
        // Wait for write response
        get_write_response(trans);
    endtask
    
    // Drive Write Address Channel
    virtual task drive_write_addr(axi_transaction trans);
        // Apply address delay
        repeat(trans.addr_delay) @(vif.master_cb);
        
        // Drive address
        vif.master_cb.awaddr  <= trans.addr;
        vif.master_cb.awvalid <= 1'b1;
        
        `uvm_info(get_type_name(), 
                 $sformatf("Write Address: 0x%0h", trans.addr), 
                 UVM_HIGH)
        
        // Wait for handshake
        @(vif.master_cb);
        while (!vif.master_cb.awready) begin
            @(vif.master_cb);
        end
        
        // Deassert valid
        vif.master_cb.awvalid <= 1'b0;
        vif.master_cb.awaddr  <= 32'h0;
    endtask
    
    // Drive Write Data Channel
    virtual task drive_write_data(axi_transaction trans);
        // Apply data delay
        repeat(trans.data_delay) @(vif.master_cb);
        
        // Drive data
        vif.master_cb.wdata  <= trans.data;
        vif.master_cb.wstrb  <= trans.strb;
        vif.master_cb.wvalid <= 1'b1;
        
        `uvm_info(get_type_name(), 
                 $sformatf("Write Data: 0x%0h, Strb: 0x%0h", trans.data, trans.strb), 
                 UVM_HIGH)
        
        // Wait for handshake
        @(vif.master_cb);
        while (!vif.master_cb.wready) begin
            @(vif.master_cb);
        end
        
        // Deassert valid
        vif.master_cb.wvalid <= 1'b0;
        vif.master_cb.wdata  <= 32'h0;
        vif.master_cb.wstrb  <= 4'h0;
    endtask
    
    // Get Write Response
    virtual task get_write_response(axi_transaction trans);
        // Apply response delay
        repeat(trans.resp_delay) @(vif.master_cb);
        
        // Assert BREADY
        vif.master_cb.bready <= 1'b1;
        
        // Wait for BVALID
        @(vif.master_cb);
        while (!vif.master_cb.bvalid) begin
            @(vif.master_cb);
        end
        
        // Capture response
        trans.resp = axi_transaction::resp_type_e'(vif.master_cb.bresp);
        
        `uvm_info(get_type_name(), 
                 $sformatf("Write Response: %s", trans.resp.name()), 
                 UVM_HIGH)
        
        // Deassert BREADY
        @(vif.master_cb);
        vif.master_cb.bready <= 1'b0;
    endtask
    
    // Drive Read Transaction
    virtual task drive_read(axi_transaction trans);
        // Drive read address
        drive_read_addr(trans);
        
        // Get read data
        get_read_data(trans);
    endtask
    
    // Drive Read Address Channel
    virtual task drive_read_addr(axi_transaction trans);
        // Apply address delay
        repeat(trans.addr_delay) @(vif.master_cb);
        
        // Drive address
        vif.master_cb.araddr  <= trans.addr;
        vif.master_cb.arvalid <= 1'b1;
        
        `uvm_info(get_type_name(), 
                 $sformatf("Read Address: 0x%0h", trans.addr), 
                 UVM_HIGH)
        
        // Wait for handshake
        @(vif.master_cb);
        while (!vif.master_cb.arready) begin
            @(vif.master_cb);
        end
        
        // Deassert valid
        vif.master_cb.arvalid <= 1'b0;
        vif.master_cb.araddr  <= 32'h0;
    endtask
    
    // Get Read Data
    virtual task get_read_data(axi_transaction trans);
        // Apply response delay
        repeat(trans.resp_delay) @(vif.master_cb);
        
        // Assert RREADY
        vif.master_cb.rready <= 1'b1;
        
        // Wait for RVALID
        @(vif.master_cb);
        while (!vif.master_cb.rvalid) begin
            @(vif.master_cb);
        end
        
        // Capture data and response
        trans.read_data = vif.master_cb.rdata;
        trans.resp = axi_transaction::resp_type_e'(vif.master_cb.rresp);
        
        `uvm_info(get_type_name(), 
                 $sformatf("Read Data: 0x%08h, Response: %s", 
                          trans.read_data, trans.resp.name()), 
                 UVM_HIGH)
        
        // Deassert RREADY
        @(vif.master_cb);
        vif.master_cb.rready <= 1'b0;
    endtask
    
endclass : axi_driver
