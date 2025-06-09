module ALU_rtl_design #(parameter N = 8, M = 4) (
    input [N-1:0] OPA, OPB,
    input CLK, RST, CE, MODE, CIN,
    input [1:0] INP_VALID,
    input [M-1:0] CMD,
    output reg [(2*N) - 1:0] RES = 0,
    output reg COUT = 1'b0,
    output reg OFLOW = 1'b0,
    output reg G = 1'b0,
    output reg E = 1'b0,
    output reg L = 1'b0,
    output reg ERR = 1'b0
);
    localparam ADD = 0,
          SUB = 1,
          ADD_CIN = 2,
          SUB_CIN = 3,
          INC_A = 4,
          DEC_A = 5,
          INC_B = 6,
          DEC_B = 7,
          CMP = 8,
          INC_MUL = 9,
          SHL1_A_MUL_B = 10,
          ADD_SIGN = 11,
          SUB_SIGN = 12,

          //logical

          AND = 0,
         NAND = 1,
         OR = 2,
         NOR = 3,
         XOR = 4,
         XNOR = 5,
         NOT_A = 6,
         NOT_B = 7,
         SHR1_A = 8,
         SHL1_A = 9,
         SHR1_B = 10,
         SHL1_B = 11,
         ROL_A_B = 12,
         ROR_A_B = 13;

    reg [N-1:0] opa_t, opb_t;
    reg [M-1:0] cmd_t;
    reg [1:0] inp_valid_t;
    reg [(2*N) -1:0] res_t, mul_res;
    reg cin_t, mode_t, ce_t, cout_t, oflow_t, err_t, g_t, e_t, l_t;

    localparam rot_bits = $clog2(N);
    wire [rot_bits-1:0] rot_val = opb_t[rot_bits-1:0];

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            opa_t <= 0;
            opb_t <= 0;
            cmd_t <= 0;
            inp_valid_t <= 0;
            res_t <= 0;
            mul_res <= 0;
            cin_t <= 0;
            mode_t <= 0;
            ce_t <= 0;
            cout_t <= 0;
            oflow_t <= 0;
            err_t <= 0;
            g_t <= 0;
            e_t <= 0;
            l_t <= 0;
        end
        else if(cmd_t == INC_MUL || cmd_t == SHL1_A_MUL_B)begin
            res_t <= mul_res;
            RES <= res_t;
            opa_t <= OPA;
            opb_t <= OPB;
            cmd_t <= CMD;
            inp_valid_t <= INP_VALID;
            cin_t <= CIN;
            mode_t <= MODE;
            ce_t <= CE;
            COUT <= cout_t;
            OFLOW <= oflow_t;
            ERR <= err_t;
            G <= g_t;
            E <= e_t;
            L <= l_t;
        end
        else begin
            opa_t <= OPA;
            opb_t <= OPB;
            cmd_t <= CMD;
            inp_valid_t <= INP_VALID;
            cin_t <= CIN;
            mode_t <= MODE;
            ce_t <= CE;
            RES <= res_t;
            COUT <= cout_t;
            OFLOW <= oflow_t;
            ERR <= err_t;
            G <= g_t;
            E <= e_t;
            L <= l_t;
        end
end

always @(*) begin
    if (RST) begin
        res_t = 0;
        cout_t = 0;
        oflow_t = 0;
        err_t = 0;
        g_t = 0;
        e_t = 0;
        l_t = 0;
    end else begin
        if (ce_t) begin
            cout_t = 0;
            oflow_t = 0;
            err_t = 0;
            g_t = 0;
            e_t = 0;
            l_t = 0;
            case (inp_valid_t)
                2'b00: begin
                    err_t = 1'b1;
                    res_t = 0;
                end

                2'b01: begin
                    if (mode_t) begin
                        case (cmd_t)
                            INC_A: begin
                                    res_t = opa_t + 1;
                                    cout_t = res_t[N];
                            end
                            DEC_A: begin
                                    res_t = opa_t - 1;
                                    cout_t = res_t[N];
                            end
                            default: begin
                                err_t = 1'b1;
                                res_t = 0;
                            end
                        endcase
                    end else begin
                        case (cmd_t)
                            NOT_A: res_t = {{N{1'b0}}, ~opa_t};
                            SHR1_A: res_t = {{N{1'b0}}, opa_t >> 1};
                            SHL1_A: res_t = {{N{1'b0}}, opa_t << 1};
                            default: begin
                                err_t = 1'b1;
                                res_t = 0;
                            end
                        endcase
                    end
                end
                2'b10: begin
                    if (mode_t) begin
                        case (cmd_t)
                            INC_B: begin
                                res_t = opb_t + 1;
                                cout_t = res_t[N];
                            end
                            DEC_B: begin
                                res_t = opb_t - 1;
                                cout_t = res_t[N];
                            end
                            default: begin
                                err_t = 1'b1;
                                res_t = 0;
                            end
                        endcase
                    end else begin
                        case (cmd_t)
                            NOT_B: res_t = {{N{1'b0}}, ~opb_t};
                            SHR1_B: res_t = {{N{1'b0}}, opb_t >> 1};
                            SHL1_B: res_t = {{N{1'b0}}, opb_t << 1};
                            default: begin
                                err_t = 1'b1;
                                res_t = 0;
                            end
                        endcase
                    end
                end
                2'b11: begin
                    if (mode_t) begin
                        case (cmd_t)
                            ADD: begin
                                res_t = opa_t + opb_t;
                                cout_t = res_t[N];
                            end
                            SUB: begin
                                res_t = opa_t - opb_t;
                                oflow_t = (opa_t < opb_t)?1:0;
                            end
                            ADD_CIN: begin
                                res_t = opa_t + opb_t + cin_t;
                                cout_t = res_t[N];
                            end
                            SUB_CIN: begin
                                res_t = opa_t - opb_t - cin_t;
                                oflow_t = res_t[N];
                            end
                            INC_A: begin
                                res_t = opa_t + 1;
                                cout_t = res_t[N];
                            end
                            DEC_A: begin
                                res_t = opa_t - 1;
                                oflow_t = res_t[N];
                            end
                            INC_B: begin
                                res_t = opb_t + 1;
                                cout_t = res_t[N];
                            end
                            DEC_B: begin
                                res_t = opb_t - 1;
                                oflow_t = res_t[N];
                            end
                            CMP: begin
                                if (opa_t < opb_t) l_t = 1'b1;
                                else if (opa_t == opb_t) e_t = 1'b1;
                                else g_t = 1'b1;
                            end
                            INC_MUL: begin
                                    mul_res = (opa_t + 1) * (opb_t + 1);
                                end

                            SHL1_A_MUL_B: begin
                                    mul_res = (opa_t << 1) * (opb_t);
                                end

                            ADD_SIGN: begin
                                res_t = $signed(opa_t) + $signed(opb_t);
                                oflow_t = ((opa_t[N-1] == opb_t[N-1]) && (res_t[N-1] != opa_t[N-1]))?1'b1:1'b0;
                                l_t = ($signed(opa_t) < $signed(opb_t));
                                e_t = ($signed(opa_t) == $signed(opb_t));
                                g_t = ($signed(opa_t) > $signed(opb_t));
                            end
                            SUB_SIGN: begin
                                res_t = $signed(opa_t) - $signed(opb_t);
                                oflow_t = ((opa_t[N-1] == opb_t[N-1]) && (res_t[N-1] != opa_t[N-1]))?1'b1:1'b0;
                                l_t = ($signed(opa_t) < $signed(opb_t));
                                e_t = ($signed(opa_t) == $signed(opb_t));
                                g_t = ($signed(opa_t) > $signed(opb_t));
                            end
                            default: begin
                                err_t = 1;
                                res_t = 0;
                            end
                        endcase
                    end else begin
                        case (cmd_t)
                            AND: res_t = {{N{1'b0}}, opa_t & opb_t};
                            NAND: res_t = {{N{1'b0}}, ~(opa_t & opb_t)};
                            OR: res_t = {{N{1'b0}}, opa_t | opb_t};
                            NOR: res_t = {{N{1'b0}}, ~(opa_t | opb_t)};
                            XOR: res_t = {{N{1'b0}}, opa_t ^ opb_t};
                            XNOR: res_t = {{N{1'b0}}, ~(opa_t ^ opb_t)};
                            NOT_A: res_t ={{N{1'b0}}, ~opa_t};
                            NOT_B: res_t = {{N{1'b0}}, ~opb_t};
                            SHR1_A: res_t = {{N{1'b0}}, opa_t >> 1};
                            SHL1_A: res_t = {{N{1'b0}}, opa_t << 1};
                            SHR1_B: res_t = {{N{1'b0}}, opb_t >> 1};
                            SHL1_B: res_t = {{N{1'b0}}, opb_t << 1};
                            ROL_A_B: begin
                                res_t = {{N{1'b0}}, (opa_t << rot_val) | (opa_t >> (N - rot_val))};
                                err_t = (opb_t[N - 1:rot_bits] > 0);
                            end
                            ROR_A_B: begin
                                res_t = {{N{1'b0}}, (opa_t >> rot_val) | (opa_t << (N - rot_val))};
                                err_t = (opb_t[N - 1:rot_bits] > 0);
                            end
                            default: begin
                                res_t = 0;
                                err_t = 1'b1;
                            end
                        endcase
                    end
                end
                default: begin
                    res_t = 0;
                    err_t = 1'b1;
                end
            endcase
        end
        else begin
            res_t = res_t;
            err_t = 0;
            G = 0;
            E = 0;
            L = 0;
            oflow_t = 0;
            cout_t = 0;
        end
    end
end
endmodule
