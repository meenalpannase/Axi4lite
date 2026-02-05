// ==============================================================================
// File: scoreboard.sv
// Description: Scoreboard with reference model
// ==============================================================================

class scoreboard extends uvm_scoreboard;
    
    `uvm_component_utils(scoreboard)
    
    // Analysis FIFOs
    uvm_tlm_analysis_fifo #(axi_transaction) axi_fifo;
    uvm_tlm_analysis_fifo #(output_item) output_fifo;
    
    // Reference model registers
    bit [31:0] led_reg;
    bit [31:0] sevenseg_reg;
    bit [31:0] irq_status_reg;
    bit [7:0]  led_prev;
    
    // Statistics
    int total_transactions;
    int passed_checks;
    int failed_checks;
    
    // Constructor
    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction
    
    // Build Phase
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        axi_fifo = new("axi_fifo", this);
        output_fifo = new("output_fifo", this);
    endfunction
    
    // Run Phase
    virtual task run_phase(uvm_phase phase);
        axi_transaction axi_trans;
        
        forever begin
            axi_fifo.get(axi_trans);
            total_transactions++;
            
            `uvm_info(get_type_name(), 
                     $sformatf("Processing transaction #%0d:\n%s", 
                              total_transactions, axi_trans.convert2string()), 
                     UVM_HIGH)
            
            // Process transaction through reference model
            process_transaction(axi_trans);
        end
    endtask
    
    // Process Transaction (Reference Model)
    virtual function void process_transaction(axi_transaction trans);
        bit [31:0] expected_data;
        bit        check_passed;
        
        if (trans.trans_type == axi_transaction::WRITE) begin
            // Write operation
            case (trans.addr[5:2])
                4'h0: begin // LED Register
                    // Apply byte strobes
                    if (trans.strb[0]) led_reg[7:0]   = trans.data[7:0];
                    if (trans.strb[1]) led_reg[15:8]  = trans.data[15:8];
                    if (trans.strb[2]) led_reg[23:16] = trans.data[23:16];
                    if (trans.strb[3]) led_reg[31:24] = trans.data[31:24];
                    
                    `uvm_info(get_type_name(), 
                             $sformatf("REF: LED_REG = 0x%08h", led_reg), 
                             UVM_MEDIUM)
                    
                    // Check for IRQ trigger condition
                    if (led_reg[7:0] == 8'hFF && led_prev != 8'hFF) begin
                        irq_status_reg[0] = 1'b1;
                        `uvm_info(get_type_name(), 
                                 "REF: IRQ triggered (LED 0x00->0xFF edge)", 
                                 UVM_MEDIUM)
                    end
                    led_prev = led_reg[7:0];
                end
                
                4'h1: begin // Seven-Segment Register
                    // Apply byte strobes
                    if (trans.strb[0]) sevenseg_reg[7:0]   = trans.data[7:0];
                    if (trans.strb[1]) sevenseg_reg[15:8]  = trans.data[15:8];
                    if (trans.strb[2]) sevenseg_reg[23:16] = trans.data[23:16];
                    if (trans.strb[3]) sevenseg_reg[31:24] = trans.data[31:24];
                    
                    `uvm_info(get_type_name(), 
                             $sformatf("REF: SEVENSEG_REG = 0x%08h", sevenseg_reg), 
                             UVM_MEDIUM)
                end
                
                4'h2: begin // IRQ Status Register (W1C)
                    if (trans.data[0]) begin
                        irq_status_reg[0] = 1'b0;
                        `uvm_info(get_type_name(), 
                                 "REF: IRQ cleared (W1C)", 
                                 UVM_MEDIUM)
                    end
                end
                
                default: begin
                    `uvm_warning(get_type_name(), 
                               $sformatf("Write to invalid address: 0x%0h", trans.addr))
                end
            endcase
            
            // Check write response
            check_passed = (trans.resp == axi_transaction::OKAY);
            if (check_passed) begin
                passed_checks++;
                `uvm_info(get_type_name(), "CHECK PASSED: Write response is OKAY", UVM_MEDIUM)
            end else begin
                failed_checks++;
                `uvm_error(get_type_name(), 
                          $sformatf("CHECK FAILED: Expected OKAY, got %s", trans.resp.name()))
            end
            
        end else begin
            // Read operation
            case (trans.addr[5:2])
                4'h0: expected_data = led_reg;
                4'h1: expected_data = sevenseg_reg;
                4'h2: expected_data = irq_status_reg;
                default: expected_data = 32'hDEADBEEF;
            endcase
            
            // Compare read data
            check_passed = (trans.read_data == expected_data);
            if (check_passed) begin
                passed_checks++;
                `uvm_info(get_type_name(), 
                         $sformatf("CHECK PASSED: Read data matched. Got=0x%08h, Exp=0x%08h", 
                                  trans.read_data, expected_data), 
                         UVM_MEDIUM)
            end else begin
                failed_checks++;
                `uvm_error(get_type_name(), 
                          $sformatf("CHECK FAILED: Read data mismatch. Got=0x%08h, Exp=0x%08h", 
                                   trans.read_data, expected_data))
            end
            
            // Check read response
            if (trans.resp != axi_transaction::OKAY) begin
                failed_checks++;
                `uvm_error(get_type_name(), 
                          $sformatf("CHECK FAILED: Expected OKAY, got %s", trans.resp.name()))
            end
        end
    endfunction
    
    // Check Phase - Final reporting
    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), "    SCOREBOARD FINAL REPORT", UVM_LOW)
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Total Transactions: %0d", total_transactions), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Passed Checks:      %0d", passed_checks), UVM_LOW)
        `uvm_info(get_type_name(), $sformatf("Failed Checks:      %0d", failed_checks), UVM_LOW)
        
        if (failed_checks == 0) begin
            `uvm_info(get_type_name(), "*** TEST PASSED ***", UVM_LOW)
        end else begin
            `uvm_error(get_type_name(), "*** TEST FAILED ***")
        end
        `uvm_info(get_type_name(), "========================================", UVM_LOW)
    endfunction
    
    // Report Phase
    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        if (failed_checks > 0) begin
            `uvm_fatal(get_type_name(), 
                      $sformatf("Test failed with %0d errors", failed_checks))
        end
    endfunction
    
endclass : scoreboard
