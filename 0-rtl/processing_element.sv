module processing_element # (
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic clk,
    input  logic rst_n,

    // control
    input  logic valid_in,
    input  logic clear_acc,

    // incoming operands
    input  logic signed [DATA_WIDTH-1:0] activation_in,
    input  logic signed [DATA_WIDTH-1:0] weight_in,

    // operands forwarded to neighboring PEs
    output logic signed [DATA_WIDTH-1:0] activation_out,
    output logic signed [DATA_WIDTH-1:0] weight_out,
    output logic                         valid_out,

    // local output-stationary accumulator
    output logic signed [ACC_WIDTH-1:0] accumulator_out
);

    /*
    1. All of my RTL logic lives here
    2. All combinational/registered logic are defined here
    3. Use these during testbenches/simulations 
    */

    // int8 x int8 produces an int16 product
    logic signed [(2*DATA_WIDTH)-1:0] product;

    // combinational signed multiplication
    assign product = activation_in * weight_in;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            activation_out <= '0;
            weight_out     <= '0;
            valid_out      <= 1'b0;
            accumulator_out <= '0;
        end
        else begin
            // move operands one processing element farther through the systolic array
            activation_out <= activation_in;
            weight_out     <= weight_in;
            valid_out      <= valid_in;

            // clear_acc has priority over accumulation
            if (clear_acc) begin
                accumulator_out <= '0;
            end
            else if (valid_in) begin
                accumulator_out <= accumulator_out + product;
            end
        end
    end

    /*
    1. My formal properties live here
    2. All asserts, assumes, and covers are defined here
    3. Use these during SymbiYosys for formal verification
    */

endmodule