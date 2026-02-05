// ==============================================================================
// File: tests.sv
// Description: UVM Tests
// ==============================================================================

// Base Test
class base_test extends uvm_test;
    
    `uvm_component_utils(base_test)
    
    env             tb_env;
    virtual axi_if  vif;
    
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Get virtual interface
        if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found")
        
        // Set interface for all components
        uvm_config_db#(virtual axi_if)::set(this, "*", "vif", vif);
        
        // Create environment
        tb_env = env::type_id::create("tb_env", this);
    endfunction
    
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        // Apply reset
        apply_reset();
        
        phase.drop_objection(this);
    endtask
    
    virtual task apply_reset();
        `uvm_info(get_type_name(), "Applying reset", UVM_LOW)
        vif.rst_n = 1'b0;
        repeat(10) @(posedge vif.clk);
        vif.rst_n = 1'b1;
        `uvm_info(get_type_name(), "Reset released", UVM_LOW)
        repeat(5) @(posedge vif.clk);
    endtask
    
endclass : base_test


// TEST-001: Reset Test
class reset_test extends base_test;
    
    `uvm_component_utils(reset_test)
    
    function new(string name = "reset_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        reset_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        seq = reset_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        
        #1000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : reset_test


// TEST-002: Basic Write Test
class basic_write_test extends base_test;
    
    `uvm_component_utils(basic_write_test)
    
    function new(string name = "basic_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        basic_write_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        seq = basic_write_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        
        #1000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : basic_write_test


// TEST-003: Basic Read Test
class basic_read_test extends base_test;
    
    `uvm_component_utils(basic_read_test)
    
    function new(string name = "basic_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        basic_write_sequence wr_seq;
        basic_read_sequence rd_seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        // First write some data
        wr_seq = basic_write_sequence::type_id::create("wr_seq");
        wr_seq.start(tb_env.axi_agt.sequencer);
        
        #500ns;
        
        // Then read it back
        rd_seq = basic_read_sequence::type_id::create("rd_seq");
        rd_seq.start(tb_env.axi_agt.sequencer);
        
        #1000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : basic_read_test


// TEST-004 to TEST-008: Protocol Compliance (Combined)
class protocol_test extends base_test;
    
    `uvm_component_utils(protocol_test)
    
    function new(string name = "protocol_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        read_write_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        // Protocol compliance is checked by assertions in interface
        // This test exercises various handshake scenarios
        seq = read_write_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        
        #2000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : protocol_test


// TEST-009 to TEST-011: Register Read/Write Test
class register_test extends base_test;
    
    `uvm_component_utils(register_test)
    
    function new(string name = "register_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        read_write_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        seq = read_write_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        
        #3000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : register_test


// TEST-012: WSTRB Test
class wstrb_test extends base_test;
    
    `uvm_component_utils(wstrb_test)
    
    function new(string name = "wstrb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        wstrb_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        seq = wstrb_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        
        #2000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : wstrb_test


// TEST-013 to TEST-017: IRQ Tests
class irq_test extends base_test;
    
    `uvm_component_utils(irq_test)
    
    function new(string name = "irq_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        irq_gen_sequence seq1;
        irq_multiple_sequence seq2;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        // Single IRQ generation
        seq1 = irq_gen_sequence::type_id::create("seq1");
        seq1.start(tb_env.axi_agt.sequencer);
        
        #1000ns;
        
        // Multiple IRQ cycles
        seq2 = irq_multiple_sequence::type_id::create("seq2");
        seq2.start(tb_env.axi_agt.sequencer);
        
        #3000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : irq_test


// TEST-018 to TEST-021: Concurrent Operations
class concurrent_test extends base_test;
    
    `uvm_component_utils(concurrent_test)
    
    function new(string name = "concurrent_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        concurrent_rw_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        seq = concurrent_rw_sequence::type_id::create("seq");
        seq.start(tb_env.axi_agt.sequencer);
        
        #5000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : concurrent_test


// TEST-026: Stress Test
class stress_test extends base_test;
    
    `uvm_component_utils(stress_test)
    
    function new(string name = "stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        random_sequence seq;
        
        phase.raise_objection(this);
        
        apply_reset();
        
        // Run multiple random sequences
        for (int i = 0; i < 10; i++) begin
            seq = random_sequence::type_id::create($sformatf("seq_%0d", i));
            assert(seq.randomize() with {num_transactions inside {[50:100]};});
            seq.start(tb_env.axi_agt.sequencer);
            #500ns;
        end
        
        #5000ns;
        
        phase.drop_objection(this);
    endtask
    
endclass : stress_test


// Full Regression Test
class regression_test extends base_test;
    
    `uvm_component_utils(regression_test)
    
    function new(string name = "regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    virtual task run_phase(uvm_phase phase);
        reset_sequence        seq_rst;
        basic_write_sequence  seq_wr;
        basic_read_sequence   seq_rd;
        wstrb_sequence        seq_strb;
        irq_gen_sequence      seq_irq;
        irq_multiple_sequence seq_irq_mult;
        concurrent_rw_sequence seq_conc;
        random_sequence       seq_rand;
        
        phase.raise_objection(this);
        
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "   STARTING FULL REGRESSION TEST", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        
        apply_reset();
        
        // Test 1: Reset verification
        `uvm_info(get_type_name(), "Running: Reset Test", UVM_LOW)
        seq_rst = reset_sequence::type_id::create("seq_rst");
        seq_rst.start(tb_env.axi_agt.sequencer);
        #500ns;
        
        // Test 2: Basic writes
        `uvm_info(get_type_name(), "Running: Basic Write Test", UVM_LOW)
        seq_wr = basic_write_sequence::type_id::create("seq_wr");
        seq_wr.start(tb_env.axi_agt.sequencer);
        #500ns;
        
        // Test 3: Basic reads
        `uvm_info(get_type_name(), "Running: Basic Read Test", UVM_LOW)
        seq_rd = basic_read_sequence::type_id::create("seq_rd");
        seq_rd.start(tb_env.axi_agt.sequencer);
        #500ns;
        
        // Test 4: WSTRB test
        `uvm_info(get_type_name(), "Running: WSTRB Test", UVM_LOW)
        seq_strb = wstrb_sequence::type_id::create("seq_strb");
        seq_strb.start(tb_env.axi_agt.sequencer);
        #1000ns;
        
        // Test 5: IRQ generation
        `uvm_info(get_type_name(), "Running: IRQ Generation Test", UVM_LOW)
        seq_irq = irq_gen_sequence::type_id::create("seq_irq");
        seq_irq.start(tb_env.axi_agt.sequencer);
        #1000ns;
        
        // Test 6: Multiple IRQ cycles
        `uvm_info(get_type_name(), "Running: Multiple IRQ Cycles Test", UVM_LOW)
        seq_irq_mult = irq_multiple_sequence::type_id::create("seq_irq_mult");
        seq_irq_mult.start(tb_env.axi_agt.sequencer);
        #2000ns;
        
        // Test 7: Concurrent operations
        `uvm_info(get_type_name(), "Running: Concurrent R/W Test", UVM_LOW)
        seq_conc = concurrent_rw_sequence::type_id::create("seq_conc");
        seq_conc.start(tb_env.axi_agt.sequencer);
        #2000ns;
        
        // Test 8: Random stress test
        `uvm_info(get_type_name(), "Running: Random Stress Test", UVM_LOW)
        seq_rand = random_sequence::type_id::create("seq_rand");
        assert(seq_rand.randomize() with {num_transactions == 200;});
        seq_rand.start(tb_env.axi_agt.sequencer);
        #5000ns;
        
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "   REGRESSION TEST COMPLETED", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        
        phase.drop_objection(this);
    endtask
    
endclass : regression_test
