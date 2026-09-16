module pe #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input logic clk,
    input logic rst_n,

    // control
    input logic clear_acc,

    // activation stream: left -> right
    input  logic signed [DATA_WIDTH-1:0] activation_in,
    input  logic                         activation_valid_in,
    output logic signed [DATA_WIDTH-1:0] activation_out,
    output logic                         activation_valid_out,

    // weight stream: top -> bottom
    input  logic signed [DATA_WIDTH-1:0] weight_in,
    input  logic                         weight_valid_in,
    output logic signed [DATA_WIDTH-1:0] weight_out,
    output logic                         weight_valid_out,

    // output-stationary accumulator
    output logic signed [ACC_WIDTH-1:0] accumulator_out
);

    /*
    1. All of my RTL logic lives here
    2. All combinational/registered logic are defined here
    3. Use these during testbenches/simulations 
    */

    logic signed [(2*DATA_WIDTH)-1:0] product;

    assign product = activation_in * weight_in;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            activation_out       <= '0;
            activation_valid_out <= 1'b0;
            weight_out           <= '0;
            weight_valid_out     <= 1'b0;
            accumulator_out      <= '0;
        end
        else begin
            // propagate activation stream horizontally
            activation_out       <= activation_in;
            activation_valid_out <= activation_valid_in;

            // propagate weight stream vertically
            weight_out           <= weight_in;
            weight_valid_out     <= weight_valid_in;

            if (clear_acc) begin
                accumulator_out <= '0;
            end
            else if (activation_valid_in && weight_valid_in) begin
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