//
//--------------------------------------------------------------------------------
//          THIS FILE WAS AUTOMATICALLY GENERATED BY THE GENESIS2 ENGINE        
//  FOR MORE INFORMATION: OFER SHACHAM (CHIP GENESIS INC / STANFORD VLSI GROUP)
//    !! THIS VERSION OF GENESIS2 IS NOT FOR ANY COMMERCIAL USE !!
//     FOR COMMERCIAL LICENSE CONTACT SHACHAM@ALUMNI.STANFORD.EDU
//--------------------------------------------------------------------------------
//
//  
//	-----------------------------------------------
//	|            Genesis Release Info             |
//	|  $Change: 11879 $ --- $Date: 2013/06/11 $   |
//	-----------------------------------------------
//	
//
//  Source file: /Users/hanrahan/git/CGRAGenerator/hardware/generator_z/pe_new/pe/rtl/test_pe.svp
//  Source template: test_pe
//
// --------------- Begin Pre-Generation Parameters Status Report ---------------
//
//	From 'generate' statement (priority=5):
// Parameter mult_mode 	= 1
// Parameter use_div 	= 0
// Parameter en_double 	= 0
// Parameter reg_out 	= 0
// Parameter use_cntr 	= 0
// Parameter use_shift 	= 1
// Parameter use_add 	= 1
// Parameter reg_inputs 	= 1
// Parameter is_msb 	= 0
// Parameter lut_inps 	= 3
// Parameter use_bool 	= 1
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From Command Line input (priority=4):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From XML input (priority=3):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From Config File input (priority=2):
//
// ---------------- End Pre-Generation Pramameters Status Report ----------------

// reg_inputs (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// reg_out (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// use_add (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// use_cntr (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// use_bool (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// use_shift (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// mult_mode (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// use_div (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// is_msb (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// en_double (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// debug (_GENESIS2_DECLARATION_PRIORITY_) = 0
//
// lut_inps (_GENESIS2_INHERITANCE_PRIORITY_) = 3
//

module   test_pe_unq1  #(
  parameter DataWidth = 16
) (
  input                clk,
  input                rst_n,
  input                clk_en,

  input         [31:0] cfg_d,
  input         [7:0]  cfg_a,
  input                cfg_en,


  input  [DataWidth-1:0]        data0,//op_a_in,
  input  [DataWidth-1:0]        data1,//op_b_in,
  input                         bit0,//op_d_p_in,
  input                         bit1,//op_e_p_in,
  input                         bit2,//op_f_p_in,




  output logic [DataWidth-1:0]  res,
  output logic                  res_p
);

logic  [DataWidth-1:0]        op_a;
logic  [DataWidth-1:0]        op_b;
logic                         op_d_p;
logic                         op_e_p;
logic                         op_f_p;

logic [DataWidth-1:0] comp_res;
logic                 comp_res_p;
logic                 res_p_w;



logic [15:0] inp_code;
logic [15:0] op_code;
always_ff @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    inp_code <= 'h0;
    op_code  <= 'h0;
  end else if(cfg_en && (&cfg_a)) begin
    inp_code <= cfg_d[31:16];
    op_code  <= cfg_d[15:0];
  end
end


test_opt_reg #(.DataWidth(DataWidth)) test_opt_reg_a
(
  .clk        (clk),
  .clk_en     (clk_en),
  .rst_n      (rst_n),
  .load       (cfg_en && (cfg_a == 8'hF0)),
  .val        (cfg_d[DataWidth-1:0]),
  .mode       (inp_code[1:0]),
  .data_in    (data0),//op_a_in),
  .res        (op_a)
);


logic                 op_b_ld;
logic [DataWidth-1:0] op_b_val;

  assign op_b_ld  = cfg_en && (cfg_a == 8'hF1);
  assign op_b_val = cfg_d[DataWidth-1:0];


test_opt_reg #(.DataWidth(DataWidth)) test_opt_reg_b
(
  .clk        (clk),
  .clk_en     (clk_en),
  .rst_n      (rst_n),
  .load       (op_b_ld),
  .val        (op_b_val),
  .mode       (inp_code[3:2]),
  .data_in    (data1),//op_b_in),
  .res        (op_b)
);




test_opt_reg #(.DataWidth(1)) test_opt_reg_d
(
  .clk        (clk),
  .clk_en     (clk_en),
  .rst_n      (rst_n),
  .load       (cfg_en && (cfg_a == 8'hF3)),
  .val        (cfg_d[0]),
  .mode       (inp_code[9:8]),
  .data_in    (bit_in0),//op_d_p_in),
  .res        (op_d_p)
);

test_opt_reg #(.DataWidth(1)) test_opt_reg_e
(
  .clk        (clk),
  .clk_en     (clk_en),
  .rst_n      (rst_n),
  .load       (cfg_en && (cfg_a == 8'hF4)),
  .val        (cfg_d[0]),
  .mode       (inp_code[11:10]),
  .data_in    (bit_in1),//op_e_p_in),
  .res        (op_e_p)
);

test_opt_reg #(.DataWidth(1)) test_opt_reg_f
(
  .clk        (clk),
  .clk_en     (clk_en),
  .rst_n      (rst_n),
  .load       (cfg_en && (cfg_a == 8'hF5)),
  .val        (cfg_d[0]),
  .mode       (inp_code[13:12]),
  .data_in    (bit_in2),//op_f_p_in),
  .res        (op_f_p)
);






test_pe_comp_unq1  test_pe_comp
(
  .op_code (op_code[8:0]),

  .op_a     (op_a),
  .op_b     (op_b),
  .op_d_p   (op_d_p),







  .res      (comp_res),
  .res_p    (comp_res_p)
);

logic res_lut;


test_lut #(.DataWidth(1)) test_lut
(
  .cfg_clk  (clk),
  .cfg_rst_n(rst_n),
  .cfg_d    (cfg_d[15:0]),
  .cfg_a    (cfg_a),
  .cfg_en   (cfg_en),

  .op_a_in  (op_d_p),
  .op_b_in  (op_e_p),
  .op_c_in  (op_f_p),

  .res      (res_lut)
);

  assign res_p_w = op_code[9] ? res_lut : comp_res_p;



  assign res   = comp_res;
  assign res_p = res_p_w;

endmodule




