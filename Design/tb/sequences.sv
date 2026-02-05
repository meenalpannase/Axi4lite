// ==============================================================================
// File: sequences.sv
// Description: Test sequences
// ==============================================================================

// Base Sequence
class base_sequence extends uvm_sequence #(axi_transaction);
    
    `uvm_object_utils(base_sequence)
    
    function new(string name = "base_sequence");
        super.new(name);
    endfunction
    
    // Helper task for write
    task write_reg(bit [31:0] addr, bit [31:0] data, bit [3:0] strb = 4'b1111);
        axi_transaction trans;
        trans = axi_transaction::type_id::create("trans");
        start_item(trans);
        trans.set_write_trans(addr, data, strb);
        finish_item(trans);
    endtask
    
    // Helper task for read
    task read_reg(bit [31:0] addr, output bit [31:0] data);
        axi_transaction trans;
        trans = axi_transaction::type_id::create("trans");
        start_item(trans);
        trans.set_read_trans(addr);
        finish_item(trans);
        get_response(trans);
        data = trans.read_data;
    endtask
    
endclass : base_sequence


// Reset Sequence
class reset_sequence extends base_sequence;
    
    `uvm_object_utils(reset_sequence)
    
    function new(string name = "reset_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        bit [31:0] read_data;
        
        `uvm_info(get_type_name(), "Verifying reset state", UVM_LOW)
        
        // Read all registers - should be 0 after reset
        read_reg(32'h0, read_data);
        if (read_data != 32'h0)
            `uvm_error(get_type_name(), $sformatf("LED reg not 0 after reset: 0x%0h", read_data))
        
        read_reg(32'h4, read_data);
        if (read_data != 32'h0)
            `uvm_error(get_type_name(), $sformatf("SEG reg not 0 after reset: 0x%0h", read_data))
        
        read_reg(32'h8, read_data);
        if (read_data != 32'h0)
            `uvm_error(get_type_name(), $sformatf("IRQ reg not 0 after reset: 0x%0h", read_data))
    endtask
    
endclass : reset_sequence


// Basic Write Sequence
class basic_write_sequence extends base_sequence;
    
    `uvm_object_utils(basic_write_sequence)
    
    function new(string name = "basic_write_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info(get_type_name(), "Starting basic write sequence", UVM_LOW)
        
        // Write to LED register
        write_reg(32'h0, 32'hAA);
        #100ns;
        
        // Write to SEVENSEG register
        write_reg(32'h4, 32'h55);
        #100ns;
    endtask
    
endclass : basic_write_sequence


// Basic Read Sequence
class basic_read_sequence extends base_sequence;
    
    `uvm_object_utils(basic_read_sequence)
    
    function new(string name = "basic_read_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        bit [31:0] read_data;
        
        `uvm_info(get_type_name(), "Starting basic read sequence", UVM_LOW)
        
        // Read LED register
        read_reg(32'h0, read_data);
        `uvm_info(get_type_name(), $sformatf("LED reg: 0x%0h", read_data), UVM_LOW)
        
        // Read SEVENSEG register
        read_reg(32'h4, read_data);
        `uvm_info(get_type_name(), $sformatf("SEG reg: 0x%0h", read_data), UVM_LOW)
        
        // Read IRQ register
        read_reg(32'h8, read_data);
        `uvm_info(get_type_name(), $sformatf("IRQ reg: 0x%0h", read_data), UVM_LOW)
    endtask
    
endclass : basic_read_sequence


// Read-Write Sequence
class read_write_sequence extends base_sequence;
    
    `uvm_object_utils(read_write_sequence)
    
    function new(string name = "read_write_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        bit [31:0] read_data;
        bit [31:0] write_val;
        
        `uvm_info(get_type_name(), "Starting read-write sequence", UVM_LOW)
        
        for (int i = 0; i < 10; i++) begin
            write_val = $urandom();
            
            // Write and read back LED register
            write_reg(32'h0, write_val);
            #50ns;
            read_reg(32'h0, read_data);
            
            // Write and read back SEVENSEG register
            write_val = $urandom();
            write_reg(32'h4, write_val);
            #50ns;
            read_reg(32'h4, read_data);
        end
    endtask
    
endclass : read_write_sequence


// WSTRB Test Sequence
class wstrb_sequence extends base_sequence;
    
    `uvm_object_utils(wstrb_sequence)
    
    function new(string name = "wstrb_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        bit [31:0] read_data;
        
        `uvm_info(get_type_name(), "Starting WSTRB sequence", UVM_LOW)
        
        // Initialize register
        write_reg(32'h0, 32'h00000000);
        #50ns;
        
        // Test byte 0 only
        write_reg(32'h0, 32'hDEADBEEF, 4'b0001);
        #50ns;
        read_reg(32'h0, read_data);
        `uvm_info(get_type_name(), $sformatf("WSTRB=0001: 0x%08h (expected 0x000000EF)", read_data), UVM_LOW)
        
        // Test byte 1 only
        write_reg(32'h0, 32'hDEADBEEF, 4'b0010);
        #50ns;
        read_reg(32'h0, read_data);
        `uvm_info(get_type_name(), $sformatf("WSTRB=0010: 0x%08h (expected 0x0000BEEF)", read_data), UVM_LOW)
        
        // Test byte 2 only
        write_reg(32'h0, 32'hDEADBEEF, 4'b0100);
        #50ns;
        read_reg(32'h0, read_data);
        `uvm_info(get_type_name(), $sformatf("WSTRB=0100: 0x%08h (expected 0x00ADBEEF)", read_data), UVM_LOW)
        
        // Test byte 3 only
        write_reg(32'h0, 32'hDEADBEEF, 4'b1000);
        #50ns;
        read_reg(32'h0, read_data);
        `uvm_info(get_type_name(), $sformatf("WSTRB=1000: 0x%08h (expected 0xDEADBEEF)", read_data), UVM_LOW)
    endtask
    
endclass : wstrb_sequence


// IRQ Generation Sequence
class irq_gen_sequence extends base_sequence;
    
    `uvm_object_utils(irq_gen_sequence)
    
    function new(string name = "irq_gen_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        bit [31:0] read_data;
        
        `uvm_info(get_type_name(), "Starting IRQ generation sequence", UVM_LOW)
        
        // Clear LED register
        write_reg(32'h0, 32'h00);
        #100ns;
        
        // Check IRQ is not asserted
        read_reg(32'h8, read_data);
        `uvm_info(get_type_name(), $sformatf("IRQ status before trigger: 0x%0h", read_data), UVM_LOW)
        
        // Trigger IRQ by writing 0xFF to LED
        `uvm_info(get_type_name(), "Triggering IRQ (0x00 -> 0xFF)", UVM_LOW)
        write_reg(32'h0, 32'hFF);
        #100ns;
        
        // Check IRQ is asserted
        read_reg(32'h8, read_data);
        `uvm_info(get_type_name(), $sformatf("IRQ status after trigger: 0x%0h", read_data), UVM_LOW)
        
        // Clear IRQ (W1C)
        `uvm_info(get_type_name(), "Clearing IRQ (W1C)", UVM_LOW)
        write_reg(32'h8, 32'h1);
        #100ns;
        
        // Check IRQ is cleared
        read_reg(32'h8, read_data);
        `uvm_info(get_type_name(), $sformatf("IRQ status after clear: 0x%0h", read_data), UVM_LOW)
    endtask
    
endclass : irq_gen_sequence


// IRQ Multiple Cycles Sequence
class irq_multiple_sequence extends base_sequence;
    
    `uvm_object_utils(irq_multiple_sequence)
    
    function new(string name = "irq_multiple_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        bit [31:0] read_data;
        
        `uvm_info(get_type_name(), "Starting multiple IRQ cycle sequence", UVM_LOW)
        
        for (int i = 0; i < 5; i++) begin
            `uvm_info(get_type_name(), $sformatf("IRQ cycle %0d", i+1), UVM_LOW)
            
            // Set LED to non-0xFF value
            write_reg(32'h0, $urandom_range(0, 254));
            #50ns;
            
            // Trigger IRQ
            write_reg(32'h0, 32'hFF);
            #50ns;
            
            // Verify IRQ asserted
            read_reg(32'h8, read_data);
            if (read_data[0] != 1'b1)
                `uvm_error(get_type_name(), "IRQ not asserted after trigger")
            
            // Clear IRQ
            write_reg(32'h8, 32'h1);
            #50ns;
            
            // Verify IRQ cleared
            read_reg(32'h8, read_data);
            if (read_data[0] != 1'b0)
                `uvm_error(get_type_name(), "IRQ not cleared after W1C")
        end
    endtask
    
endclass : irq_multiple_sequence


// Random Sequence
class random_sequence extends base_sequence;
    
    `uvm_object_utils(random_sequence)
    
    rand int num_transactions;
    
    constraint c_num_trans {
        num_transactions inside {[50:100]};
    }
    
    function new(string name = "random_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        axi_transaction trans;
        bit [31:0] read_data;
        
        `uvm_info(get_type_name(), 
                 $sformatf("Starting random sequence with %0d transactions", num_transactions), 
                 UVM_LOW)
        
        for (int i = 0; i < num_transactions; i++) begin
            trans = axi_transaction::type_id::create("trans");
            start_item(trans);
            assert(trans.randomize());
            finish_item(trans);
            
            if (trans.trans_type == axi_transaction::READ) begin
                get_response(trans);
            end
            
            #($urandom_range(10, 50));
        end
    endtask
    
endclass : random_sequence


// Concurrent Read/Write Sequence
class concurrent_rw_sequence extends base_sequence;
    
    `uvm_object_utils(concurrent_rw_sequence)
    
    function new(string name = "concurrent_rw_sequence");
        super.new(name);
    endfunction
    
    virtual task body();
        `uvm_info(get_type_name(), "Starting concurrent read/write sequence", UVM_LOW)
        
        fork
            begin
                // Write operations
                for (int i = 0; i < 10; i++) begin
                    write_reg(32'h0, $urandom());
                    #($urandom_range(20, 50));
                end
            end
            begin
                // Read operations
                bit [31:0] data;
                for (int i = 0; i < 10; i++) begin
                    read_reg(32'h4, data);
                    #($urandom_range(20, 50));
                end
            end
        join
    endtask
    
endclass : concurrent_rw_sequence
