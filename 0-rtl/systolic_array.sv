module systolic_array #(
    parameter int ARRAY_SIZE = 8,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input logic clk,
    input logic rst_n,
    input logic clear_acc,
    input logic signed [DATA_WIDTH-1:0] activation_in [ARRAY_SIZE],
    input logic activation_valid_in [ARRAY_SIZE],
    input logic signed [DATA_WIDTH-1:0] weight_in [ARRAY_SIZE],
    input logic weight_valid_in [ARRAY_SIZE],

    // one accumulated result per processing element
    output logic signed [ACC_WIDTH-1:0] result [ARRAY_SIZE][ARRAY_SIZE]
);

    /*
    1. All of my RTL logic lives here
    2. All combinational/registered logic are defined here
    3. Use these during testbenches/simulations 
    */

    logic signed [DATA_WIDTH-1:0] activation_bus [ARRAY_SIZE][ARRAY_SIZE+1];
    logic activation_valid_bus [ARRAY_SIZE][ARRAY_SIZE+1];

    logic signed [DATA_WIDTH-1:0] weight_bus [ARRAY_SIZE+1][ARRAY_SIZE];

    logic weight_valid_bus [ARRAY_SIZE+1][ARRAY_SIZE];


    generate
        for (genvar row = 0; row < ARRAY_SIZE; row++) begin
            assign activation_bus[row][0] =
                activation_in[row];
            assign activation_valid_bus[row][0] =
                activation_valid_in[row];
        end
        for (genvar col = 0; col < ARRAY_SIZE; col++) begin
            assign weight_bus[0][col] =
                weight_in[col];
            assign weight_valid_bus[0][col] =
                weight_valid_in[col];
        end
    endgenerate

    generate
        for (genvar row = 0; row < ARRAY_SIZE; row++) begin : GEN_ROW
            for (genvar col = 0; col < ARRAY_SIZE; col++) begin : GEN_COL
                pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH (ACC_WIDTH)
                ) pe_inst (
                    .clk                  (clk),
                    .rst_n                (rst_n),

                    .clear_acc            (clear_acc),

                    .activation_in        (activation_bus[row][col]),
                    .activation_valid_in  (activation_valid_bus[row][col]),

                    .activation_out       (activation_bus[row][col+1]),
                    .activation_valid_out (activation_valid_bus[row][col+1]),

                    .weight_in            (weight_bus[row][col]),
                    .weight_valid_in      (weight_valid_bus[row][col]),

                    .weight_out           (weight_bus[row+1][col]),
                    .weight_valid_out     (weight_valid_bus[row+1][col]),

                    .accumulator_out      (result[row][col])
                );
            end
        end
    endgenerate

    /*
    1. My formal properties live here
    2. All asserts, assumes, and covers are defined here
    3. Use these during SymbiYosys for formal verification
    */

endmodule