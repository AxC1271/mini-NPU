`timescale 1ns / 1ps

module tb_pe;

    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;
    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst_n;
    logic clear_acc;

    logic signed [DATA_WIDTH-1:0] activation_in;
    logic                         activation_valid_in;
    logic signed [DATA_WIDTH-1:0] activation_out;
    logic                         activation_valid_out;

    logic signed [DATA_WIDTH-1:0] weight_in;
    logic                         weight_valid_in;
    logic signed [DATA_WIDTH-1:0] weight_out;
    logic                         weight_valid_out;

    logic signed [ACC_WIDTH-1:0] accumulator_out;

    integer pass_count;
    integer fail_count;


    processing_element #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH (ACC_WIDTH)
    ) dut (
        .clk                  (clk),
        .rst_n                (rst_n),
        .clear_acc            (clear_acc),
        .activation_in        (activation_in),
        .activation_valid_in  (activation_valid_in),
        .activation_out       (activation_out),
        .activation_valid_out (activation_valid_out),
        .weight_in            (weight_in),
        .weight_valid_in      (weight_valid_in),
        .weight_out           (weight_out),
        .weight_valid_out     (weight_valid_out),
        .accumulator_out      (accumulator_out)
    );


    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    task automatic check_acc(
        input logic signed [ACC_WIDTH-1:0] expected,
        input string name
    );
        begin
            if ($signed(accumulator_out) === $signed(expected)) begin
                $display("PASS: %-35s expected=%0d actual=%0d",
                         name, $signed(expected), $signed(accumulator_out));
                pass_count++;
            end
            else begin
                $display("FAIL: %-35s expected=%0d actual=%0d",
                         name, $signed(expected), $signed(accumulator_out));
                fail_count++;
            end
        end
    endtask


    task automatic apply_inputs(
        input logic signed [DATA_WIDTH-1:0] activation,
        input logic                         activation_valid,
        input logic signed [DATA_WIDTH-1:0] weight,
        input logic                         weight_valid
    );
        begin
            @(negedge clk);

            activation_in       = activation;
            activation_valid_in = activation_valid;

            weight_in           = weight;
            weight_valid_in     = weight_valid;

            clear_acc = 1'b0;

            @(posedge clk);
            #1;
        end
    endtask


    task automatic clear_accumulator;
        begin
            @(negedge clk);

            clear_acc            = 1'b1;
            activation_valid_in  = 1'b0;
            weight_valid_in      = 1'b0;

            @(posedge clk);
            #1;

            @(negedge clk);
            clear_acc = 1'b0;
        end
    endtask


    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n               = 1'b0;
        clear_acc           = 1'b0;
        activation_in       = '0;
        activation_valid_in = 1'b0;
        weight_in           = '0;
        weight_valid_in     = 1'b0;

        $display("\nTEST 1: RESET");

        @(posedge clk);
        #1;

        check_acc(0, "Reset accumulator");

        if ((activation_valid_out === 1'b0) &&
            (weight_valid_out === 1'b0)) begin
            $display("PASS: Reset valid outputs");
            pass_count++;
        end
        else begin
            $display("FAIL: Reset valid outputs");
            fail_count++;
        end

        @(negedge clk);
        rst_n = 1'b1;

        $display("\nTEST 2: BOTH OPERANDS VALID");

        apply_inputs(3, 1'b1, 2, 1'b1);
        check_acc(6, "3 * 2");


        $display("\nTEST 3: ACTIVATION ONLY");

        apply_inputs(50, 1'b1, 50, 1'b0);
        check_acc(6, "Weight invalid prevents MAC");


        $display("\nTEST 4: WEIGHT ONLY");

        apply_inputs(50, 1'b0, 50, 1'b1);
        check_acc(6, "Activation invalid prevents MAC");


        $display("\nTEST 5: BOTH INVALID");

        apply_inputs(100, 1'b0, 100, 1'b0);
        check_acc(6, "Both invalid prevent MAC");


        $display("\nTEST 6: VALID PROPAGATION");

        apply_inputs(-7, 1'b1, 12, 1'b0);

        if (($signed(activation_out) === -7) &&
            (activation_valid_out === 1'b1) &&
            ($signed(weight_out) === 12) &&
            (weight_valid_out === 1'b0)) begin

            $display("PASS: Independent valid propagation");
            pass_count++;

        end
        else begin
            $display("FAIL: Independent valid propagation");
            fail_count++;
        end


        $display("\nTEST 7: CLEAR");

        clear_accumulator();
        check_acc(0, "Clear accumulator");
        

        $display("\nTEST 8: SIGNED DOT PRODUCT");

        apply_inputs( 3, 1'b1,  2, 1'b1);
        apply_inputs( 4, 1'b1, -1, 1'b1);
        apply_inputs(-2, 1'b1,  5, 1'b1);
        apply_inputs( 6, 1'b1,  3, 1'b1);

        check_acc(10, "Signed dot product");


        $display("\nTEST 9: INT8 EXTREME");

        clear_accumulator();

        apply_inputs(-128, 1'b1, -128, 1'b1);
        check_acc(16384, "-128 * -128");


        $display("\nTEST 10: CLEAR PRIORITY");

        @(negedge clk);

        activation_in       = 50;
        activation_valid_in = 1'b1;
        weight_in           = 50;
        weight_valid_in     = 1'b1;
        clear_acc           = 1'b1;

        @(posedge clk);
        #1;

        check_acc(0, "Clear overrides valid MAC");


        $display("\n========================================");
        $display("PE VERIFICATION RESULTS");
        $display("========================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if (fail_count == 0)
            $display("\n*** ALL PE TESTS PASSED ***\n");
        else
            $display("\n*** PE TEST FAILED ***\n");

        $finish;

    end
endmodule