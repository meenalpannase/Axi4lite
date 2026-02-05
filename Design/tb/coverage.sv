// ==============================================================================
// File: coverage.sv
// Description: Functional coverage collector
// ==============================================================================

class coverage_collector extends uvm_subscriber #(axi_transaction);
    
    `uvm_component_utils(coverage_collector)
    
    // Virtual Interface for output monitoring
    virtual axi_if vif;
    
    // Coverage variables
    bit [31:0] addr;
    bit [31:0] data;
    bit [3:0]  strb;
    bit [1:0]  resp;
    bit        is_read;
    bit        is_write;
    bit [7:0]  led_value;
    bit [7:0]  sevenseg_value;
    bit        irq_status;
    
    // Coverage Groups
    
    // Register Access Coverage
    covergroup cg_register_access;
        option.per_instance = 1;
        option.name = "register_access_cov";
        
        cp_addr: coverpoint addr {
            bins led_reg     = {32'h0};
            bins sevenseg_reg = {32'h4};
            bins irq_reg     = {32'h8};
            bins invalid     = default;
        }
        
        cp_access_type: coverpoint is_write {
            bins read  = {0};
            bins write = {1};
        }
        
        cx_reg_access: cross cp_addr, cp_access_type;
    endgroup
    
    // Write Strobe Coverage
    covergroup cg_wstrb;
        option.per_instance = 1;
        option.name = "wstrb_cov";
        
        cp_strb: coverpoint strb {
            bins byte0         = {4'b0001};
            bins byte1         = {4'b0010};
            bins byte2         = {4'b0100};
            bins byte3         = {4'b1000};
            bins halfword_low  = {4'b0011};
            bins halfword_high = {4'b1100};
            bins word          = {4'b1111};
            bins other         = default;
        }
        
        cp_addr_strb: coverpoint addr {
            bins led_reg = {32'h0};
            bins seg_reg = {32'h4};
        }
        
        cx_addr_strb: cross cp_addr_strb, cp_strb;
    endgroup
    
    // LED Pattern Coverage
    covergroup cg_led_patterns;
        option.per_instance = 1;
        option.name = "led_pattern_cov";
        
        cp_led: coverpoint led_value {
            bins all_off    = {8'h00};
            bins all_on     = {8'hFF};
            bins pattern_aa = {8'hAA};
            bins pattern_55 = {8'h55};
            bins low_nibble = {[8'h01:8'h0F]};
            bins high_nibble = {[8'hF0:8'hFE]};
            bins others = default;
        }
    endgroup
    
    // Seven-Segment Pattern Coverage
    covergroup cg_sevenseg_patterns;
        option.per_instance = 1;
        option.name = "sevenseg_pattern_cov";
        
        cp_sevenseg: coverpoint sevenseg_value {
            bins all_off = {8'h00};
            bins all_on  = {8'hFF};
            bins digit_0 = {8'h3F}; // Common 7-seg encoding
            bins digit_1 = {8'h06};
            bins digit_2 = {8'h5B};
            bins digit_3 = {8'h4F};
            bins digit_4 = {8'h66};
            bins digit_5 = {8'h6D};
            bins digit_6 = {8'h7D};
            bins digit_7 = {8'h07};
            bins digit_8 = {8'h7F};
            bins digit_9 = {8'h6F};
            bins others = default;
        }
    endgroup
    
    // IRQ Coverage
    covergroup cg_irq;
        option.per_instance = 1;
        option.name = "irq_cov";
        
        cp_irq_status: coverpoint irq_status {
            bins not_asserted = {0};
            bins asserted     = {1};
        }
        
        cp_led_trigger: coverpoint led_value {
            bins trigger_value = {8'hFF};
            bins non_trigger   = default;
        }
        
        cx_irq_led: cross cp_irq_status, cp_led_trigger;
    endgroup
    
    // Response Coverage
    covergroup cg_response;
        option.per_instance = 1;
        option.name = "response_cov";
        
        cp_resp: coverpoint resp {
            bins okay   = {2'b00};
            bins exokay = {2'b01};
            bins slverr = {2'b10};
            bins decerr = {2'b11};
        }
        
        cp_trans_type: coverpoint is_write {
            bins read  = {0};
            bins write = {1};
        }
        
        cx_resp_type: cross cp_resp, cp_trans_type;
    endgroup
    
    // Constructor
    function new(string name = "coverage_collector", uvm_component parent = null);
        super.new(name, parent);
        cg_register_access = new();
        cg_wstrb = new();
        cg_led_patterns = new();
        cg_sevenseg_patterns = new();
        cg_irq = new();
        cg_response = new();
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Virtual interface not found")
    endfunction
    
    // Write method (called by analysis port)
    virtual function void write(axi_transaction t);
        addr = t.addr;
        data = t.data;
        strb = t.strb;
        resp = t.resp;
        is_read = (t.trans_type == axi_transaction::READ);
        is_write = (t.trans_type == axi_transaction::WRITE);
        
        // Sample current output values
        led_value = vif.led_out;
        sevenseg_value = vif.sevenseg_out;
        irq_status = vif.irq_out;
        
        // Sample coverage
        cg_register_access.sample();
        cg_response.sample();
        
        if (is_write) begin
            cg_wstrb.sample();
        end
        
        // Sample output-specific coverage
        if (addr == 32'h0) begin
            cg_led_patterns.sample();
            cg_irq.sample();
        end else if (addr == 32'h4) begin
            cg_sevenseg_patterns.sample();
        end
    endfunction
    
    // Report Phase
    virtual function void report_phase(uvm_phase phase);
        real reg_cov, wstrb_cov, led_cov, seg_cov, irq_cov, resp_cov, total_cov;
        
        super.report_phase(phase);
        
        reg_cov = cg_register_access.get_coverage();
        wstrb_cov = cg_wstrb.get_coverage();
        led_cov = cg_led_patterns.get_coverage();
        seg_cov = cg_sevenseg_patterns.get_coverage();
        irq_cov = cg_irq.get_coverage();
        resp_cov = cg_response.get_coverage();
        total_cov = $get_coverage();
        
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "    FUNCTIONAL COVERAGE REPORT", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Register Access Coverage:  %0.2f%%", reg_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("WSTRB Coverage:            %0.2f%%", wstrb_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("LED Pattern Coverage:      %0.2f%%", led_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Seven-Segment Coverage:    %0.2f%%", seg_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("IRQ Coverage:              %0.2f%%", irq_cov), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Response Coverage:         %0.2f%%", resp_cov), UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("TOTAL COVERAGE:            %0.2f%%", total_cov), UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
    endfunction
    
endclass : coverage_collector
