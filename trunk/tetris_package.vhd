library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.vga_package.all;

package tetris_package is
	constant  BOARD_COLUMNS    : positive   := 10;
	constant  BOARD_ROWS       : positive   := 20;
	constant  BLOCKS_PER_PIECE : positive   := 4;

	type      shape_type     is (SHAPE_T, SHAPE_SQUARE, SHAPE_STICK, SHAPE_L_L, SHAPE_L_R, SHAPE_DOG_L, SHAPE_DOG_R);
	attribute enum_encoding  : string;
	attribute enum_encoding  of shape_type : type is "one-hot";
	
	-- Board declarations
	type board_cell_type is record
		filled       : std_logic;
		shape        : shape_type;
	end record;	

	type board_cell_array is array(natural range <>, natural range <>) of board_cell_type;
	
	type board_type is record
		cells        :  board_cell_array(0 to (BOARD_COLUMNS-1), 0 to (BOARD_ROWS-1));
	end record;

	-- Piece declarations
	type block_pos_type is record
		col         : integer range 0 to (BOARD_COLUMNS-1);
		row         : integer range 0 to (BOARD_ROWS-1);
	end record;
	
	type block_pos_array is array(natural range <>) of block_pos_type;
	
	type piece_type is record
		shape        : shape_type;
		blocks       : block_pos_array(0 to (BLOCKS_PER_PIECE-1));
	end record;

	-- Piece definitions
	constant PIECE_T : piece_type :=
	(
		shape  => SHAPE_T,
		blocks =>
		(
			(col => 1, row => 0),
			(col => 0, row => 0),
			(col => 2, row => 0),
			(col => 1, row => 1)
		)
	);

	constant PIECE_SQUARE : piece_type :=
	(
		shape  => SHAPE_SQUARE,
		blocks =>
		(
			(col => 0, row => 0),
			(col => 1, row => 0),
			(col => 0, row => 1),
			(col => 1, row => 1)
		)
	);	
	
	constant PIECE_STICK : piece_type :=
	(
		shape  => SHAPE_STICK,
		blocks =>
		(
			(col => 0, row => 1),
			(col => 0, row => 0),
			(col => 0, row => 2),
			(col => 0, row => 3)
		)
	);	

	constant PIECE_L : piece_type :=
	(
		shape  => SHAPE_L_L,
		blocks =>
		(
			(col => 1, row => 0),
			(col => 0, row => 0),
			(col => 2, row => 0),
			(col => 0, row => 1)
		)
	);	
	
	constant PIECE_LR : piece_type :=
	(
		shape  => SHAPE_L_R,
		blocks =>
		(
			(col => 1, row => 0),
			(col => 0, row => 0),
			(col => 2, row => 0),
			(col => 2, row => 1)
		)
	);
	
	constant PIECE_DOG_L : piece_type :=
	(
		shape  => SHAPE_DOG_L,
		blocks =>
		(
			(col => 1, row => 0),
			(col => 1, row => 1),
			(col => 2, row => 0),
			(col => 0, row => 1)
		)
	);	
	
	constant PIECE_DOG_R : piece_type :=
	(
		shape  => SHAPE_DOG_R,
		blocks =>
		(
			(col => 1, row => 0),
			(col => 1, row => 1),
			(col => 0, row => 0),
			(col => 2, row => 1)
		)
	);	
	
	function Lookup_color(shape : shape_type) return color_type;
end package;


package body tetris_package is
	
	function Lookup_color(shape : shape_type)
		return color_type is
		variable color : color_type;
	begin
		case (shape) is
			when SHAPE_T =>
				color := COLOR_YELLOW;
			when SHAPE_SQUARE =>
				color := COLOR_MAGENTA;
			when SHAPE_STICK =>
				color := COLOR_ORANGE;
			when SHAPE_L_L | SHAPE_L_R =>
				color := COLOR_CYAN;
			when SHAPE_DOG_L | SHAPE_DOG_R =>
				color := COLOR_GREEN;
		end case;
		return color;
	end function;

end package body;

