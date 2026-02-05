// ==============================================================================
// File: axi_transaction.sv
// Description: AXI4-Lite transaction class
// ==============================================================================

class axi_transaction extends uvm_sequence_item;
    
    // Transaction Type
    typedef enum {READ, WRITE} trans_type_e;
    
    // AXI Response Types
    typedef enum bit[1:0] {
        OKAY   = 2'b00,
        EXOKAY = 2'b01,
        SLVERR = 2'b10,
        DECERR = 2'b11
    } resp_type_e;
    
    // Transaction Fields
    rand trans_type_e   trans_type;
    rand bit [31:0]     addr;
    rand bit [31:0]     data;
    rand bit [3:0]      strb;
    
    // Response Fields
    resp_type_e         resp;
    bit [31:0]          read_data;
    
    // Timing Controls
    rand int unsigned   addr_delay;  // Delay before asserting AWVALID/ARVALID
    rand int unsigned   data_delay;  // Delay before asserting WVALID
    rand int unsigned   resp_delay;  // Delay before asserting BREADY/RREADY
    
    // Constraints
    constraint c_valid_addr {
        addr inside {32'h0, 32'h4, 32'h8};
    }
    
    constraint c_valid_strb {
        strb != 4'b0000;
        strb inside {4'b0001, 4'b0010, 4'b0100, 4'b1000,
                     4'b0011, 4'b1100, 4'b1111};
    }
    
    constraint c_reasonable_delays {
        addr_delay inside {[0:10]};
        data_delay inside {[0:10]};
        resp_delay inside {[0:10]};
    }
    
    // UVM Automation
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_enum(trans_type_e, trans_type, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(strb, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(resp_type_e, resp, UVM_ALL_ON)
        `uvm_field_int(read_data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(addr_delay, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(data_delay, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(resp_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end
    
    // Constructor
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction
    
    // Constraint for READ transactions
    function void set_read_trans(bit[31:0] address);
        trans_type = READ;
        addr = address;
    endfunction
    
    // Constraint for WRITE transactions
    function void set_write_trans(bit[31:0] address, bit[31:0] wdata, bit[3:0] wstrb = 4'b1111);
        trans_type = WRITE;
        addr = address;
        data = wdata;
        strb = wstrb;
    endfunction
    
    // Display transaction
    function string convert2string();
        string s;
        s = $sformatf("\n----- AXI Transaction -----\n");
        s = {s, $sformatf("Type: %s\n", trans_type.name())};
        s = {s, $sformatf("Addr: 0x%0h\n", addr)};
        if (trans_type == WRITE) begin
            s = {s, $sformatf("Data: 0x%08h\n", data)};
            s = {s, $sformatf("Strb: 0b%04b\n", strb)};
        end else begin
            s = {s, $sformatf("Read Data: 0x%08h\n", read_data)};
        end
        s = {s, $sformatf("Resp: %s\n", resp.name())};
        s = {s, $sformatf("Delays: [addr:%0d, data:%0d, resp:%0d]\n", 
                         addr_delay, data_delay, resp_delay)};
        s = {s, "-------------------------\n"};
        return s;
    endfunction
    
endclass : axi_transaction
