library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.tetris_package.all;
use work.vga_package.all;


entity Tetris_Datapath is
	port
	(
		CLOCK           : in  std_logic;
		RESET_N         : in  std_logic;
		
		-- Connections for the Controller
		CLEAR           : in  std_logic;
		MOVE_DOWN       : in  std_logic;
		MOVE_LEFT       : in  std_logic;
		MOVE_RIGHT      : in  std_logic;
		ROTATE          : in  std_logic;
		MERGE           : in  std_logic;
		REMOVE_ROW      : in  std_logic;
		NEW_PIECE       : in  std_logic;
		NEW_PIECE_TYPE  : in  piece_type;
		ROW_INDEX       : in  integer range 0 to (BOARD_ROWS-1);
		CAN_MOVE_LEFT   : out std_logic;
		CAN_MOVE_RIGHT  : out std_logic;
		CAN_MOVE_DOWN   : out std_logic;
		CAN_ROTATE      : out std_logic;
		ROW_IS_COMPLETE : out std_logic;
		-- Connections for the View
		QUERY_CELL      : in  block_pos_type;
		CELL_CONTENT    : out board_cell_type
	);

end entity;


architecture RTL of Tetris_Datapath is
	signal board                   : board_type;
	signal falling_piece           : piece_type;
	signal next_falling_piece      : piece_type;
	type   affected_by_merge_type  is array(natural range <>, natural range <>) of std_logic;
	signal cell_affected_by_merge  : affected_by_merge_type(0 to BOARD_COLUMNS-1, 0 to BOARD_ROWS-1);
	
begin

	FallingPiece_RTL : process(CLOCK, RESET_N)
		constant PIECE_AT_RESET   : piece_type := PIECE_SQUARE;	
		constant NEW_PIECE_OFFSET : integer    := BOARD_COLUMNS/2 - 2;
	begin
		if (RESET_N = '0') then
			
			falling_piece <= PIECE_AT_RESET;
			
		elsif (rising_edge(CLOCK)) then
						
			if (NEW_PIECE = '1') then
			
				falling_piece.shape <= NEW_PIECE_TYPE.shape;
				for i in 0 to BLOCKS_PER_PIECE-1 loop
					falling_piece.blocks(i).row <= NEW_PIECE_TYPE.blocks(i).row;
					falling_piece.blocks(i).col <= NEW_PIECE_TYPE.blocks(i).col + NEW_PIECE_OFFSET;
				end loop;
			
			else
			
				falling_piece <= next_falling_piece;
				
			end if;
		end if;
	end process;
	
	
	NextFallingPiece : process(falling_piece, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT, ROTATE)
	begin
		next_falling_piece <= falling_piece;
				
		for i in 0 to BLOCKS_PER_PIECE-1 loop
			if (MOVE_DOWN = '1') then
				next_falling_piece.blocks(i).row <= falling_piece.blocks(i).row + 1;
			end if;
			
			if (ROTATE = '1') then
				--TODO rotation
					
			elsif (MOVE_LEFT = '1') then
				next_falling_piece.blocks(i).col <= falling_piece.blocks(i).col - 1;
			elsif (MOVE_RIGHT = '1') then
				next_falling_piece.blocks(i).col <= falling_piece.blocks(i).col + 1;
			end if;
		end loop;
	end process;
	
	
	CanMove_Signals : process(falling_piece, board)
		variable cur_block          : block_pos_type;
		variable left_cell_filled   : std_logic;
		variable right_cell_filled  : std_logic;
		variable bottom_cell_filled : std_logic;
	begin
		CAN_MOVE_LEFT  <= '1';
		CAN_MOVE_RIGHT <= '1';
		CAN_MOVE_DOWN  <= '1';
		CAN_ROTATE     <= '1'; --TODO rotation detection
		
		for i in 0 to BLOCKS_PER_PIECE-1 loop
			cur_block := falling_piece.blocks(i);
			
			if (cur_block.col = 0) then
				CAN_MOVE_LEFT <= '0';
			else
				left_cell_filled := board.cells((cur_block.col-1),cur_block.row).filled;
				if (left_cell_filled = '1') then
					CAN_MOVE_LEFT <= '0';
				end if;
			end if;

			if (cur_block.col = (BOARD_COLUMNS-1)) then
				CAN_MOVE_RIGHT <= '0';
			else
				right_cell_filled := board.cells((cur_block.col+1),cur_block.row).filled;
				if (right_cell_filled = '1') then
					CAN_MOVE_RIGHT <= '0';
				end if;
			end if;
			
			if (cur_block.row = (BOARD_ROWS-1)) then
				CAN_MOVE_DOWN <= '0';
			else
				bottom_cell_filled := board.cells(cur_block.col,(cur_block.row+1)).filled;
				if (bottom_cell_filled = '1') then
					CAN_MOVE_DOWN <= '0';
				end if;
			end if;
		end loop;
	end process;
	
	
	Board_rtl : process(CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			
			for col in 0 to BOARD_COLUMNS-1 loop
				for row in 0 to BOARD_ROWS-1 loop
					board.cells(col,row).filled <= '0';
				end loop;
			end loop;
			
		elsif (rising_edge(CLOCK)) then
		
			for col in 0 to BOARD_COLUMNS-1 loop
				for row in 0 to BOARD_ROWS-1 loop

					if (CLEAR = '1') then
						board.cells(col,row).filled <= '0';
					
					elsif (REMOVE_ROW = '1') then
						if (row = 0) then
							board.cells(col, row).filled <= '0';
						elsif (row <= ROW_INDEX) then
							board.cells(col, row) <= board.cells(col, row-1);
						end if;
					
					elsif (MERGE = '1') then
						if(cell_affected_by_merge(col, row) = '1') then
							board.cells(col, row).filled <= '1';
							board.cells(col, row).shape  <= falling_piece.shape;
						end if;
					
					end if;			
				
				end loop;
			end loop;
			
		end if;
	end process;
	
	
	AffectedByMerge : process(board, falling_piece)
	begin
		cell_affected_by_merge <= ((others=> (others=>'0')));
		
		for i in 0 to BLOCKS_PER_PIECE-1 loop	
			cell_affected_by_merge(
				falling_piece.blocks(i).col,
				falling_piece.blocks(i).row
			) <= '1';
		end loop;

	end process;
		
	
	RowCheck : process(board, ROW_INDEX)
		variable complete : std_logic;
	begin
		complete := '1';
		for i in 0 to (BOARD_COLUMNS-1) loop
			complete := complete and board.cells(i,ROW_INDEX).filled;
		end loop;
		ROW_IS_COMPLETE <= complete;
	end process;
	
	
	CellQuery : process(QUERY_CELL, board, falling_piece)
		variable selected_cell : board_cell_type;
	begin
		CELL_CONTENT.filled <= '0';
		CELL_CONTENT.shape  <= SHAPE_T; --indifferent
		
		selected_cell := board.cells(QUERY_CELL.col, QUERY_CELL.row);
		if (selected_cell.filled = '1') then
			CELL_CONTENT <= selected_cell;
		else
			for i in 0 to BLOCKS_PER_PIECE-1 loop
				if(falling_piece.blocks(i) = QUERY_CELL) then
					CELL_CONTENT.filled <= '1';
					CELL_CONTENT.shape  <= falling_piece.shape;
				end if;
			end loop;
		
		end if;
	end process;
	
end architecture;