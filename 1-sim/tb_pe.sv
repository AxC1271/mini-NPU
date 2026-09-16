`timescale 1ns/1ps

module tb_pe;

    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;
    localparam int CLK_PERIOD = 10;

    logic clk;
    logic rst_n;

    logic valid_in;
    logic clear_acc;

    logic signed [DATA_WIDTH-1:0] activation_in;
    logic signed [DATA_WIDTH-1:0] weight_in;

    logic signed [DATA_WIDTH-1:0] activation_out;
    logic signed [DATA_WIDTH-1:0] weight_out;
    logic                         valid_out;

    logic signed [ACC_WIDTH-1:0] accumulator_out;

    integer pass_count;
    integer fail_count;



    processing_element #(
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH)
    ) dut (
        .clk             (clk),
        .rst_n           (rst_n),

        .valid_in        (valid_in),
        .clear_acc       (clear_acc),

        .activation_in   (activation_in),
        .weight_in       (weight_in),

        .activation_out  (activation_out),
        .weight_out      (weight_out),
        .valid_out       (valid_out),

        .accumulator_out (accumulator_out)
    );


    initial begin
        clk = 1'b0;

        forever #(CLK_PERIOD/2)
            clk = ~clk;
    end


    task automatic check_acc(
        input logic signed [ACC_WIDTH-1:0] expected,
        input string test_name
    );
        begin
            if ($signed(accumulator_out) === $signed(expected)) begin
                $display(
                    "PASS: %-30s expected=%0d actual=%0d",
                    test_name,
                    $signed(expected),
                    $signed(accumulator_out)
                );

                pass_count++;
            end
            else begin
                $display(
                    "FAIL: %-30s expected=%0d actual=%0d",
                    test_name,
                    $signed(expected),
                    $signed(accumulator_out)
                );

                fail_count++;
            end
        end
    endtask

    task automatic check_forwarding(
        input logic signed [DATA_WIDTH-1:0] expected_activation,
        input logic signed [DATA_WIDTH-1:0] expected_weight,
        input logic                         expected_valid,
        input string                        test_name
    );
        begin
            if (
                ($signed(activation_out) === $signed(expected_activation)) &&
                ($signed(weight_out)     === $signed(expected_weight))     &&
                (valid_out               === expected_valid)
            ) begin

                $display(
                    "PASS: %-30s A=%0d W=%0d valid=%0b",
                    test_name,
                    $signed(activation_out),
                    $signed(weight_out),
                    valid_out
                );

                pass_count++;
            end
            else begin

                $display(
                    "FAIL: %-30s expected A=%0d W=%0d valid=%0b | got A=%0d W=%0d valid=%0b",
                    test_name,
                    $signed(expected_activation),
                    $signed(expected_weight),
                    expected_valid,
                    $signed(activation_out),
                    $signed(weight_out),
                    valid_out
                );

                fail_count++;
            end
        end
    endtask

    task automatic apply_mac(
        input logic signed [DATA_WIDTH-1:0] activation,
        input logic signed [DATA_WIDTH-1:0] weight
    );
        begin
            @(negedge clk);

            activation_in = activation;
            weight_in     = weight;
            valid_in      = 1'b1;
            clear_acc     = 1'b0;

            @(posedge clk);

            // wait for nonblocking assignments to update
            #1;
        end
    endtask

    initial begin

        pass_count = 0;
        fail_count = 0;

        rst_n         = 1'b0;
        valid_in      = 1'b0;
        clear_acc     = 1'b0;
        activation_in = '0;
        weight_in     = '0;

        $display("\n========================================");
        $display("TEST 1: RESET");
        $display("========================================");

        @(posedge clk);
        #1;

        check_acc(32'sd0, "Accumulator reset");

        check_forwarding(
            8'sd0,
            8'sd0,
            1'b0,
            "Pipeline reset"
        );


        // release reset
        @(negedge clk);
        rst_n = 1'b1;


        $display("\n========================================");
        $display("TEST 2: POSITIVE x POSITIVE");
        $display("========================================");

        apply_mac(
            8'sd3,
            8'sd2
        );

        check_acc(
            32'sd6,
            "3 * 2"
        );

        check_forwarding(
            8'sd3,
            8'sd2,
            1'b1,
            "Forward 3 and 2"
        );

        $display("\n========================================");
        $display("TEST 3: POSITIVE x NEGATIVE");
        $display("========================================");

        apply_mac(
            8'sd4,
            -8'sd1
        );

        check_acc(
            32'sd2,
            "6 + (4 * -1)"
        );

        $display("\n========================================");
        $display("TEST 4: NEGATIVE x POSITIVE");
        $display("========================================");

        apply_mac(
            -8'sd2,
            8'sd5
        );

        check_acc(
            -32'sd8,
            "2 + (-2 * 5)"
        );

        $display("\n========================================");
        $display("TEST 5: NEGATIVE x NEGATIVE");
        $display("========================================");

        apply_mac(
            -8'sd3,
            -8'sd4
        );

        check_acc(
            32'sd4,
            "-8 + (-3 * -4)"
        );

        $display("\n========================================");
        $display("TEST 6: INVALID CYCLE");
        $display("========================================");

        @(negedge clk);

        activation_in = 8'sd100;
        weight_in     = 8'sd100;
        valid_in      = 1'b0;
        clear_acc     = 1'b0;

        @(posedge clk);
        #1;

        check_acc(
            32'sd4,
            "Invalid does not accumulate"
        );

        check_forwarding(
            8'sd100,
            8'sd100,
            1'b0,
            "Invalid operands still forward"
        );

        $display("\n========================================");
        $display("TEST 7: CLEAR ACCUMULATOR");
        $display("========================================");

        @(negedge clk);

        clear_acc = 1'b1;
        valid_in  = 1'b0;

        @(posedge clk);
        #1;

        check_acc(
            32'sd0,
            "Clear accumulator"
        );

        @(negedge clk);

        clear_acc = 1'b0;

        $display("\n========================================");
        $display("TEST 8: DOT PRODUCT");
        $display("========================================");

        apply_mac( 8'sd3,  8'sd2);
        apply_mac( 8'sd4, -8'sd1);
        apply_mac(-8'sd2,  8'sd5);
        apply_mac( 8'sd6,  8'sd3);

        check_acc(
            32'sd10,
            "4-element dot product"
        );

        $display("\n========================================");
        $display("TEST 9: INT8 CORNER CASE");
        $display("========================================");

        @(negedge clk);

        clear_acc = 1'b1;
        valid_in  = 1'b0;

        @(posedge clk);
        #1;

        @(negedge clk);

        clear_acc = 1'b0;

        apply_mac(
            -8'sd128,
            -8'sd128
        );

        check_acc(
            32'sd16384,
            "-128 * -128"
        );

        $display("\n========================================");
        $display("TEST 10: CLEAR PRIORITY");
        $display("========================================");

        @(negedge clk);

        activation_in = 8'sd50;
        weight_in     = 8'sd50;

        valid_in  = 1'b1;
        clear_acc = 1'b1;

        @(posedge clk);
        #1;

        check_acc(
            32'sd0,
            "Clear overrides MAC"
        );

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