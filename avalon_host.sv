module avalon_host (
    input clk,
    input rst_n,
	 input reset_release,
    // AXI Stream Input
    input [127:0] s_axi_data,
    input s_axi_valid,
    input s_axi_last,
    output reg ready_out, // Added ready signal for AXI side
    input s_axi_ready,

    // Avalon-MM Output
    output reg [31:0] avm_address,
    output reg [31:0] avm_burstcount,
    output reg avm_write,
    output reg [127:0] avm_writedata,
    output reg [15:0] avm_byteenable,

    // Avalon-MM Read Input
    output reg avm_read_0,
    input avm_readdatavalid_0,
    input [127:0] avm_readdata_0
    //output reg [31:0] avm_read_address
);

    // FIFO memory
    reg [127:0] fifo_mem [0:255]; 
    reg [127:0] aval_mem [0:255]; // Memory to store the read data
    reg [7:0] wr_ptr = 0;  
    reg [7:0] rd_ptr = 0;  
    reg [7:0] fifo_count = 0;  
    reg [7:0] aval_ptr = 0;      // Pointer for reading back data

    // Define FSM states
    typedef enum reg [1:0] {
        RESET = 2'b00,    
        WRITE = 2'b01,    
        READ  = 2'b10     
    } state_t;
    state_t state, next_state;

    // FSM:
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all outputs and pointers
            state <= RESET;
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
            avm_write <= 0;
            avm_burstcount <= 1; 
            avm_read_0 <= 0;
            ready_out <= 1; // Ready to accept data initially
            aval_ptr <= 0;
        end else begin
            case (state)
                RESET: begin
                    // Reset state 
                    avm_write <= 0;
                    avm_read_0 <= 0;
                    next_state <= WRITE;
                    ready_out <= 1; 
                end

                WRITE: begin
                    // Write data from FIFO to Avalon-MM
                    if (fifo_count > 0) begin
                        avm_write <= 1;
                        avm_address <= rd_ptr * 16; 
                        avm_writedata <= fifo_mem[rd_ptr]; 
                        avm_byteenable <= 16'hFFFF;  
                        rd_ptr <= rd_ptr + 1;
                        fifo_count <= fifo_count - 1;
                    end else begin
                        avm_write <= 0;
                        next_state <= READ;
                    end
                end

                READ: begin
                    // Initiate read from Avalon-MM
                    if (fifo_count==0) begin
                        avm_read_0 <= 1;
                        //avm_read_address <= (aval_ptr * 16); 
                        avm_address <= aval_ptr * 16; 
                    end else if (avm_readdatavalid_0) begin
                        aval_mem[aval_ptr] <= avm_readdata_0; 
                        // Add read address here 
                        avm_address <= aval_ptr *16;
                        aval_ptr <= aval_ptr + 1;
                        avm_read_0 <= 0; 
                        next_state <= WRITE; 
                    end //else begin
                    // Add else condition for read valid
                        //aval_ptr<=0;
                        //avm_read_0<=0;
                        //next_state <= WRITE;
                    //end
                end

                default: begin
                    next_state <= RESET;
                end
            endcase

            // Update state transition
            state <= next_state;

            // AXI Stream data input to FIFO
            if (s_axi_valid && ready_out) begin
                fifo_mem[wr_ptr] <= s_axi_data;
                wr_ptr <= wr_ptr + 1;
                fifo_count <= fifo_count + 1;
                if (fifo_count == 255) begin
                    ready_out <= 0; 
                end
            end else if (fifo_count < 255) begin
                ready_out <= 1;  
            end
        end
    end
endmodule