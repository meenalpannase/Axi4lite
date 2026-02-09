module axi_ledseg_irq #(
    parameter ADDRESS = 32,
    parameter DATA_WIDTH = 32
)(
    input                   ACLK,
    input                   ARESETn,

    // WRITE ADDRESS CHANNEL
    input  [ADDRESS-1:0]    S_AWADDR,
    input                   S_AWVALID,
    output reg              S_AWREADY,

    //WRITE DATA CHANNEL 
    input  [DATA_WIDTH-1:0] S_WDATA,
    input  [3:0]            S_WSTRB,
    input                   S_WVALID,
    output reg              S_WREADY,

    // WRITE RESPONSE CHANNEL
    input                   S_BREADY,
    output reg              S_BVALID,
    output reg [1:0]        S_BRESP,

    //  READ ADDRESS CHANNEL 
    input  [ADDRESS-1:0]    S_ARADDR,
    input                   S_ARVALID,
    output reg              S_ARREADY,

    //  READ DATA CHANNEL 
    input                   S_RREADY,
    output reg [DATA_WIDTH-1:0] S_RDATA,
    output reg              S_RVALID,
    output reg [1:0]        S_RRESP,

    // EXTERNAL I/O 
    output reg [7:0]        LED_OUT,
    output reg [7:0]        SEVENSEG_OUT,
    output reg              IRQ_OUT
);

    
    // INTERNAL REGISTERS 
    
    // 0x00 : LED register
    // 0x04 : Seven-segment register
    // 0x08 : IRQ status (bit[0] = IRQ, W1C)
    
    reg [31:0] led_reg;
    reg [31:0] sevenseg_reg;
    reg [31:0] irq_status_reg;
    reg [7:0]  led_prev;

    reg [ADDRESS-1:0] write_addr_reg;
    reg [ADDRESS-1:0] read_addr_reg;

    
    localparam W_IDLE = 2'd0,
               W_ADDR = 2'd1,
               W_DATA = 2'd2,
               W_RESP = 2'd3;

    localparam R_IDLE = 2'd0,
               R_ADDR = 2'd1,
               R_DATA = 2'd2;

    reg [1:0] w_state, w_next;
    reg [1:0] r_state, r_next;

    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            w_state <= W_IDLE;
            r_state <= R_IDLE;
        end else begin
            w_state <= w_next;
            r_state <= r_next;
        end
    end

   
    always @(*) begin
        w_next = w_state;
        case (w_state)
            W_IDLE:  if (S_AWVALID)       
                         w_next = W_ADDR;
            W_ADDR:  if (S_AWREADY)      
                         w_next = W_DATA;
            W_DATA:  if (S_WREADY)        
                        w_next = W_RESP;
            W_RESP:  if (S_BREADY && S_BVALID)  
                        w_next = W_IDLE;
        endcase
    end

   
    always @(*) begin
        r_next = r_state;
        case (r_state)
            R_IDLE:  if (S_ARVALID) 
                         r_next = R_ADDR;
            R_ADDR:  if (S_ARREADY) 
                         r_next = R_DATA;
            R_DATA:  if (S_RREADY && S_RVALID)   
                         r_next = R_IDLE;
        endcase
    end

    
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AWREADY <= 0;
            S_WREADY  <= 0;
            S_BVALID  <= 0;
            S_ARREADY <= 0;
            S_RVALID  <= 0;
            S_RDATA   <= 0;
            S_BRESP   <= 2'b00;
            S_RRESP   <= 2'b00;

            write_addr_reg <= 0;
            read_addr_reg  <= 0;

            led_reg        <= 0;
            sevenseg_reg   <= 0;
            irq_status_reg <= 0;
            led_prev       <= 0;

            LED_OUT        <= 0;
            SEVENSEG_OUT   <= 0;
            IRQ_OUT        <= 0;
        end else begin

            
            S_AWREADY <= 0;
            S_WREADY  <= 0;
            S_ARREADY <= 0;

            //  WRITE FSM 
            case (w_state)

                W_IDLE: begin
                    S_BVALID <= 0;
                end

                W_ADDR: begin
                    S_AWREADY <= 1;
                    if (S_AWVALID)
                        write_addr_reg <= S_AWADDR;
                end

                W_DATA: begin
                    S_WREADY <= 1;
                    if (S_WVALID) begin
                        case (write_addr_reg[5:2])
                            4'h0: begin
                                if (S_WSTRB[0]) led_reg[7:0] <= S_WDATA[7:0]; 
                                if (S_WSTRB[1]) led_reg[15:8] <= S_WDATA[15:8]; 
                                if (S_WSTRB[2]) led_reg[23:16] <= S_WDATA[23:16]; 
                                if (S_WSTRB[3]) led_reg[31:24] <= S_WDATA[31:24];
                                LED_OUT <= S_WDATA[7:0];
                            end
                            4'h1: begin
                                if (S_WSTRB[0]) sevenseg_reg[7:0] <= S_WDATA[7:0]; 
                                if (S_WSTRB[1]) sevenseg_reg[15:8] <= S_WDATA[15:8]; 
                                if (S_WSTRB[2]) sevenseg_reg[23:16] <= S_WDATA[23:16]; 
                                if (S_WSTRB[3]) sevenseg_reg[31:24] <= S_WDATA[31:24];
                                SEVENSEG_OUT <= S_WDATA[7:0];
                            end
                            4'h2: begin
                                if (S_WDATA[0])
                                    irq_status_reg[0] <= 1'b0; // clearing IRQ when S_WDATA = 1
                            end
                        endcase
                    end
                end

                W_RESP: begin
                    S_BVALID <= 1;
                    S_BRESP  <= 2'b00;
                end
            endcase

            //  READ FSM
            case (r_state)

                R_IDLE: begin
                    S_RVALID <= 0;
                end

                R_ADDR: begin
                    S_ARREADY <= 1;
                    if (S_ARVALID)
                        read_addr_reg <= S_ARADDR;
                end

                R_DATA: begin
                    S_RVALID <= 1;
                    S_RRESP  <= 2'b00;
                    case (read_addr_reg[5:2])
                        4'h0: S_RDATA <= led_reg;
                        4'h1: S_RDATA <= sevenseg_reg;
                        4'h2: S_RDATA <= irq_status_reg;
                        default: S_RDATA <= 32'hDEADBEEF;
                    endcase
                end
            endcase

            //  IRQ LOGIC 
            led_prev <= led_reg[7:0];
            if (led_reg[7:0] == 8'hFF && led_prev != 8'hFF)
                irq_status_reg[0] <= 1'b1;                   // IRQ triggered when all LEDs are high (8'hFF)

            IRQ_OUT <= irq_status_reg[0];
        end
    end

endmodule
