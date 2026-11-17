module synchronizer_2_stage (
    input wire clk,
    input wire rst_n,
    input wire reset_value,
    input wire data_in,
    output reg data_out
);

    reg stage_1_ff;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_1_ff <= reset_value;
            data_out <= reset_value;
        end else begin 
            stage_1_ff <= data_in;
            data_out <= stage_1_ff;
        end
    end

endmodule


module spi_peripheral (
    input wire sclk,
    input wire cs_n,
    input wire copi,
    input wire clk,
    input wire rst_n,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);

    reg [3:0] clk_counter;

    reg sclk_reg;
    wire sclk_synced;
    wire cs_n_synced;
    wire copi_synced;

    // reg [7:0] temp_en_reg_out_7_0;
    // reg [7:0] temp_en_reg_out_15_8;
    // reg [7:0] temp_en_reg_pwm_7_0;
    // reg [7:0] temp_en_reg_pwm_15_8;
    // reg temp_pwm_duty_cycle;


    reg read_mode;
    reg [6:0] address;
    reg [7:0] data;

    reg [15:0] copi_store;

    reg data_ready;

    synchronizer_2_stage cs_n_synchronizer (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(cs_n),
        .reset_value(1),
        .data_out(cs_n_synced)
    );

    synchronizer_2_stage copi_synchronizer (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(copi),
        .reset_value(0),
        .data_out(copi_synced)
    );

    synchronizer_2_stage sclk_synchronizer (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(sclk),
        .reset_value(0),
        .data_out(sclk_synced)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_reg <= 0;
        end else begin
            sclk_reg <= sclk_synced;
        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 0;
            copi_store <= 0;
            read_mode <= 0;
            address <= 0;
            data <= 0;
            data_ready <= 0;

            en_reg_out_7_0 <= 0;
            en_reg_out_15_8 <= 0;
            en_reg_pwm_7_0 <= 0;
            en_reg_pwm_15_8 <= 0;
            pwm_duty_cycle <= 0;
        end else begin
            if (cs_n_synced) begin
                clk_counter <= 0;
            end else begin
                if (sclk_reg == 0 && sclk_synced == 1) begin
                    clk_counter <= clk_counter + 1;

                    copi_store <= copi_store << 1;
                    copi_store[0] <= copi_synced;

                    if (clk_counter == 15) begin
                        read_mode <= copi_store[14];
                        address   <= copi_store[13:7];
                        data      <= {copi_store[6:0], copi_synced};

                        data_ready <= 1;
                    end
                end
            end

            if (data_ready) begin
                if (read_mode) begin
                    case (address)
                        3'b000: en_reg_out_7_0 <= data;
                        3'b001: en_reg_out_15_8 <= data;
                        3'b010: en_reg_pwm_7_0 <= data;
                        3'b011: en_reg_pwm_15_8 <= data;
                        3'b100: pwm_duty_cycle <= data;
                    endcase
                end

                data_ready <= 0;
            end
        end
    end


endmodule