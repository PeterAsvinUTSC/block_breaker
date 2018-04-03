// Part 2 skeleton
// Code from Brick Breaker: Adrian Ensan and Julia Yan
module block_breaker(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		  LEDR,
		  SW,
		  HEX0,
		  HEX1,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [3:0]   KEY;
	input   [10:0]   SW;
	output [17:0] LEDR;
	output [6:0] HEX0;
	output [6:0] HEX1;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
    

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
	 
	 reg [5:0] state;
	 reg border_initing, paddle_initing, ball_initing, block_initing;
	 reg [7:0] x, y, p_2_x, p_2_y;
	 reg [7:0] p_x, p_y,  b_x, b_y, bl_1_x, bl_1_y, bl_2_x, bl_2_y, bl_3_x, bl_3_y, bl_4_x, bl_4_y, bl_5_x, bl_5_y, bl_6_x, bl_6_y, bl_7_x, bl_7_y, bl_8_x, bl_8_y, bl_9_x, bl_9_y, bl_10_x, bl_10_y;
	 reg [7:0] paddle_2_x, paddle_2_y;
	 reg [2:0] colour;
	 reg [3:0] score1;
	 reg [3:0] score2;
	 integer which_paddle;
	 integer level;
	 reg b_x_direction, b_y_direction;
	 reg [17:0] draw_counter;
	 reg [2:0] block_1_colour, block_2_colour, block_3_colour, block_4_colour, block_5_colour, block_6_colour, block_7_colour, block_8_colour, block_9_colour, block_10_colour;
	 wire frame;
	 
	 assign LEDR[5:0] = state;
	 // states
	 localparam  RESET_BLACK       = 6'b000000,
                INIT_PADDLE       = 6'b000001,
					 INIT_PADDLE_2     = 6'b000010,
                INIT_BALL         = 6'b000011,
                INIT_BLOCK_1      = 6'b000100,
					 INIT_BLOCK_2      = 6'b000101,
					 INIT_BLOCK_3      = 6'b000110,
					 INIT_BLOCK_4      = 6'b000111,
					 INIT_BLOCK_5      = 6'b001000,
					 INIT_SCORE			 = 6'b001001,
                IDLE              = 6'b001010,
					 ERASE_PADDLE	    = 6'b001011,
					 ERASE_PADDLE_2    = 6'b001100,
                UPDATE_PADDLE     = 6'b001101,
					 UPDATE_PADDLE_2   = 6'b001110,
					 DRAW_PADDLE	    = 6'b001111,
					 DRAW_PADDLE_2     = 6'b010000,
                ERASE_BALL        = 6'b010001,
					 UPDATE_BALL       = 6'b010010,
					 DRAW_BALL         = 6'b010011,
					 UPDATE_BLOCK_1    = 6'b010100,
					 DRAW_BLOCK_1      = 6'b010101,
					 UPDATE_BLOCK_2    = 6'b010110,
					 DRAW_BLOCK_2      = 6'b010111,
					 UPDATE_BLOCK_3    = 6'b011000,
					 DRAW_BLOCK_3      = 6'b011001,
					 UPDATE_BLOCK_4    = 6'b011010,
					 DRAW_BLOCK_4      = 6'b011011,
					 UPDATE_BLOCK_5    = 6'b011100,
					 DRAW_BLOCK_5      = 6'b011101,
					 FINISH            = 6'b011110,
					 DEAD    		    = 6'b011111;


	clock(.clock(CLOCK_50), .clk(frame));
	hex_display player1(.IN(score1), .OUT(HEX0));
	hex_display player2(.IN(score2), .OUT(HEX1));
	 assign LEDR[7] = ((b_y_direction) && (b_y > p_y - 8'd1) && (b_y < p_y + 8'd2) && (b_x >= p_x) && (b_x <= p_x + 8'd8));
	 // if SW[1] is 1 then pause
	 always@(posedge CLOCK_50 && ~SW[1])
    	 begin
			border_initing = 1'b0;
			paddle_initing = 1'b0;
			ball_initing = 1'b0;
			block_initing = 1'b0;
			colour = 3'b000;
			//colour2 = 3'b000;
			x = 8'b00000000;
			y = 8'b00000000;
			which_paddle = 1;
			p_2_x = 8'b00000000;
			p_2_y = 8'b00000000;
			score1 = 4'd0;
			score2 = 4'd0;
			level = 0;
			if (~SW[0]) state = RESET_BLACK;
        case (state)
		  RESET_BLACK: begin
			if (draw_counter < 17'b10000000000000000) begin
						x = draw_counter[7:0];
						y = draw_counter[16:8];
						p_2_x = draw_counter[7:0];
						p_2_y = draw_counter[16:8];
						draw_counter = draw_counter + 1'b1;
					end
					else begin
						draw_counter= 8'b00000000;
						state = INIT_PADDLE;
					end
		  end
    			 INIT_PADDLE: begin
					 if (draw_counter < 6'b100000) begin
					 p_x = 8'd76;
					 p_y = 8'd110;
						x = p_x + draw_counter[3:0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b111;
						end
					else begin
						draw_counter= 8'b00000000;
						state = INIT_PADDLE_2;
					end
				 end
				 //initialize top paddle
				 INIT_PADDLE_2: begin
					 if (draw_counter < 6'b100000) begin
					 paddle_2_x = 8'd76;
					 paddle_2_y = 8'd20;
						p_2_x = paddle_2_x + draw_counter[3:0];
						p_2_y = paddle_2_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b111;
						end
					else begin
						draw_counter= 8'b00000000;
						state = INIT_BALL;
					end
				 end

				 INIT_BALL: begin
					 b_x = 8'd80;
					 b_y = 8'd108;
						x = b_x;
						y = b_y;
						colour = 3'b111;
						state = INIT_BLOCK_1;
				 end
				 INIT_BLOCK_1: begin
					 bl_1_x = 8'd15;
					 bl_1_y = 8'd60;
					 block_1_colour = 3'b100;
						state = INIT_BLOCK_2;
				 end
				 INIT_BLOCK_2: begin
					 bl_2_x = 8'd45;
					 bl_2_y = 8'd60;
					 block_2_colour = 3'b100;
						state = INIT_BLOCK_3;
				 end
				 INIT_BLOCK_3: begin
					 bl_3_x = 8'd75;
					 bl_3_y = 8'd60;
					 block_3_colour = 3'b100;
						state = INIT_BLOCK_4;
				 end
				 INIT_BLOCK_4: begin
					 bl_4_x = 8'd105;
					 bl_4_y = 8'd60;
					 block_4_colour = 3'b100;
						state = INIT_BLOCK_5;
				 end
				 INIT_BLOCK_5: begin
					 bl_5_x = 8'd135;
					 bl_5_y = 8'd60;
					 block_5_colour = 3'b100;
						state = INIT_SCORE;
				 end
				 INIT_SCORE: begin
					 score1 = 4'd0;
					 score2 = 4'd0;
					 state = IDLE;
				 end
				 IDLE: begin
				 if (frame)
					state = ERASE_PADDLE;
				 end
				 ERASE_PADDLE: begin
						if (draw_counter < 6'b100000) begin
						x = p_x + draw_counter[3:0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						end
					else begin
						draw_counter= 8'b00000000;
						state = ERASE_PADDLE_2;
					end
				 end
				 //erase top paddle
				 ERASE_PADDLE_2: begin
						if (draw_counter < 6'b100000) begin
						x = paddle_2_x + draw_counter[3:0];
						y = paddle_2_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						end
					else begin
						draw_counter= 8'b00000000;
						state = UPDATE_PADDLE;
					end
				 end
				 UPDATE_PADDLE: begin
						//control speeds [if SW[3] is 1 then paddles move fast, else they move slow]
						if (~SW[3] && ~KEY[0] && p_x < 8'd144) p_x = p_x + 1'b1;
						else if (SW[3] && ~KEY[0] && p_x < 8'd144) p_x = p_x + 2'b10;
						if (~SW[3] && ~KEY[1] && p_x > 8'd0) p_x = p_x - 1'b1;
						else if (SW[3] && ~KEY[1] && p_x > 8'd0) p_x = p_x - 2'b10;
						state = UPDATE_PADDLE_2;
				 end
				 UPDATE_PADDLE_2: begin
				 //control speeds [if SW[3] is 1 then paddles move fast, else they move slow]
						if (~SW[3] && ~KEY[2] && paddle_2_x < 8'd144) paddle_2_x = paddle_2_x + 1'b1;
						else if (SW[3] && ~KEY[2] && paddle_2_x < 8'd144) paddle_2_x = paddle_2_x + 2'b10;
						if (~SW[3] && ~KEY[3] && paddle_2_x > 8'd0) paddle_2_x = paddle_2_x - 1'b1;
						else if (SW[3] && ~KEY[3] && paddle_2_x > 8'd0) paddle_2_x = paddle_2_x - 2'b10;
						state = DRAW_PADDLE;
						
				 end
				 DRAW_PADDLE: begin
					if (draw_counter < 6'b100000) begin
						x = p_x + draw_counter[3:0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b110;
						end
					else begin
						draw_counter= 8'b00000000;
						state = DRAW_PADDLE_2;
					end
				 end
				 //Draw the top paddle
				 DRAW_PADDLE_2: begin
					if (draw_counter < 6'b100000) begin
						x = paddle_2_x + draw_counter[3:0];
						y = paddle_2_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b001;
						end
					else begin
						draw_counter= 8'b00000000;
						state = ERASE_BALL;
					end
				 end
				 ERASE_BALL: begin
					x = b_x;
						y = b_y;
						state = UPDATE_BALL;
				 end
				UPDATE_BALL: begin
					//trail feature
					if (SW[2]) begin
						x = b_x;
						y = b_y;
						colour = 3'b011;
					end
					if (~b_x_direction && level == 0) b_x = b_x + 2'b01;
					else if (~b_x_direction && level == 1) b_x = b_x + 2'b10;
					else if (b_x_direction && level == 1) b_x = b_x - 2'b10;
					else b_x = b_x - 2'b01;
					if (b_y_direction && level == 0) b_y = b_y + 2'b01;
					else if (b_y_direction && level == 1) b_y = b_y + 2'b10;
					else if (~b_y_direction && level == 1) b_y = b_y - 2'b10;
					else b_y = b_y - 2'b01;
					if ((b_x == 8'd0) || (b_x == 8'd160)) 
					b_x_direction = ~b_x_direction;
			
				if ((b_y_direction) && (b_y > p_y - 8'd1) && (b_y < p_y + 8'd2) && (b_x >= p_x) && (b_x <= p_x + 8'd15)) begin
					b_y_direction = ~b_y_direction;
					which_paddle = 0;
				end
					//second paddle collision
				else if ((~b_y_direction) && (b_y > paddle_2_y - 8'd1) && (b_y < paddle_2_y + 8'd2) && (b_x >= paddle_2_x) && (b_x <= paddle_2_x + 8'd15)) begin
					b_y_direction = ~b_y_direction;
					which_paddle = 1;
					end
					if ((b_y >= 8'd120) || (b_y <= 8'd0)) state = DEAD;
					// take to finish state if all blocks are black: they've been hit
					//else if ((level == 0) && (block_1_colour == 3'b000) && (block_2_colour == 3'b000)  && (block_3_colour == 3'b000)  && (block_4_colour == 3'b000)  && (block_5_colour == 3'b000)) begin						
	//					level = 1;					
		//				state = RESET_BLACK;
					///end
					else if ((block_1_colour == 3'b000) && (block_2_colour == 3'b000)  && (block_3_colour == 3'b000)  && (block_4_colour == 3'b000)  && (block_5_colour == 3'b000))
							state = FINISH;
					else state = DRAW_BALL;
				 end
				 DRAW_BALL: begin
					
					x = b_x;
					y = b_y;
					colour = 3'b111;
					state = UPDATE_BLOCK_1;
				 end
				 UPDATE_BLOCK_1: begin
					if ((block_1_colour != 3'b000) && (b_y > bl_1_y - 8'd1) && (b_y < bl_1_y + 8'd2) && (b_x >= bl_1_x) && (b_x <= bl_1_x + 8'd7)) begin
						b_y_direction = ~b_y_direction;
						block_1_colour = 3'b000;
						score1 = score1 + 4'd1;
					end
					state = DRAW_BLOCK_1;
				 end
				 DRAW_BLOCK_1: begin
					if (draw_counter < 5'b10000) begin
						x = bl_1_x + draw_counter[2:0];
						y = bl_1_y + draw_counter[3];
						draw_counter = draw_counter + 1'b1;
						colour = block_1_colour;
						end
					else begin
						draw_counter= 8'b00000000;
						state = UPDATE_BLOCK_2;
					end
				 end
				 UPDATE_BLOCK_2: begin
					if ((block_2_colour != 3'b000) && (b_y > bl_2_y - 8'd1) && (b_y < bl_2_y + 8'd2) && (b_x >= bl_2_x) && (b_x <= bl_2_x + 8'd7)) begin
						b_y_direction = ~b_y_direction;
						block_2_colour = 3'b000;
						score1 = score1 + 4'd1;
					end
					state = DRAW_BLOCK_2;
				 end
				 DRAW_BLOCK_2: begin
					if (draw_counter < 5'b10000) begin
						x = bl_2_x + draw_counter[2:0];
						y = bl_2_y + draw_counter[3];
						draw_counter = draw_counter + 1'b1;
						colour = block_2_colour;
						end
					else begin
						draw_counter= 8'b00000000;
						state = UPDATE_BLOCK_3;
					end
				 end
				 UPDATE_BLOCK_3: begin
					if ((block_3_colour != 3'b000) && (b_y > bl_3_y - 8'd1) && (b_y < bl_3_y + 8'd2) && (b_x >= bl_3_x) && (b_x <= bl_3_x + 8'd7)) begin
						b_y_direction = ~b_y_direction;
						block_3_colour = 3'b000;
						score1 = score1 + 4'd1;
					end
					state = DRAW_BLOCK_3;
				 end
				 DRAW_BLOCK_3: begin
					if (draw_counter < 5'b10000) begin
						x = bl_3_x + draw_counter[2:0];
						y = bl_3_y + draw_counter[3];
						draw_counter = draw_counter + 1'b1;
						colour = block_3_colour;
						end
					else begin
						draw_counter= 8'b00000000;
						state = UPDATE_BLOCK_4;
					end
				 end
				 UPDATE_BLOCK_4: begin
					if ((block_4_colour != 3'b000) && (b_y > bl_4_y - 8'd1) && (b_y < bl_4_y + 8'd2) && (b_x >= bl_4_x) && (b_x <= bl_4_x + 8'd7)) begin
						b_y_direction = ~b_y_direction;
						block_4_colour = 3'b000;
						score1 = score1 + 4'd1;
					end
					state = DRAW_BLOCK_4;
				 end
				 DRAW_BLOCK_4: begin
					if (draw_counter < 5'b10000) begin
						x = bl_4_x + draw_counter[2:0];
						y = bl_4_y + draw_counter[3];
						draw_counter = draw_counter + 1'b1;
						colour = block_4_colour;
						end
					else begin
						draw_counter= 8'b00000000;
						state = UPDATE_BLOCK_5;
					end
				 end
				 UPDATE_BLOCK_5: begin
					if ((block_5_colour != 3'b000) && (b_y > bl_5_y - 8'd1) && (b_y < bl_5_y + 8'd2) && (b_x >= bl_5_x) && (b_x <= bl_5_x + 8'd7)) begin
						b_y_direction = ~b_y_direction;
						block_5_colour = 3'b000;
						score1 = score1 + 4'd1;
					end
					state = DRAW_BLOCK_5;
				 end
				 DRAW_BLOCK_5: begin
					if (draw_counter < 5'b10000) begin
						x = bl_5_x + draw_counter[2:0];
						y = bl_5_y + draw_counter[3];
						draw_counter = draw_counter + 1'b1;
						colour = block_5_colour;
						end
					else begin
						draw_counter= 8'b00000000;
						state = IDLE;
					end
				 end
				 
				 FINISH: begin
					//finish screen
					if (draw_counter <17'b10000000000000000) begin
						x = draw_counter[7:0];
						y = draw_counter[16:8];
						p_2_x = draw_counter[7:0];
						p_2_y = draw_counter[16:8];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b010;
						end
				end
				 
				 DEAD: begin

					if (draw_counter < 17'b10000000000000000) begin
						x = draw_counter[7:0];
						y = draw_counter[16:8];
						p_2_x = draw_counter[7:0];
						p_2_y = draw_counter[16:8];
						draw_counter = draw_counter + 1'b1;
						if (b_y >= 8'd120)
							colour = 3'b001;
						else
							colour = 3'b110;
						end
				end


         endcase
    end
endmodule

module clock(input clock, output clk);
reg [19:0] frame_counter;
reg frame;
	always@(posedge clock)
    begin
        if (frame_counter == 20'b00000000000000000000) begin
		  frame_counter = 20'b11001011011100110100;
		  frame = 1'b1;
		  end
        else begin
			frame_counter = frame_counter - 1'b1;
			frame = 1'b0;
		  end
    end
	 assign clk = frame;
endmodule

//hex module taken from CSCB58 course website
module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule



