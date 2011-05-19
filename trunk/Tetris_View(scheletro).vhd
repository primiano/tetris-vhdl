library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.tetris_package.all;
use work.vga_package.all;


entity Tetris_View is
	port
	(
		CLOCK          : in  std_logic;
		RESET_N        : in  std_logic;
		
		REDRAW         : in  std_logic;
		
		FB_READY       : in  std_logic;
		FB_CLEAR       : out std_logic;
		FB_DRAW_RECT   : out std_logic;
		FB_DRAW_LINE   : out std_logic;
		FB_FILL_RECT   : out std_logic;
		FB_FLIP        : out std_logic;
		FB_COLOR       : out color_type;
		FB_X0          : out xy_coord_type;
		FB_Y0          : out xy_coord_type;
		FB_X1          : out xy_coord_type;
		FB_Y1          : out xy_coord_type;
		
		QUERY_CELL     : out block_pos_type;
		CELL_CONTENT   : in  board_cell_type
		
	);
end entity;


architecture RTL of Tetris_View is
	constant LEFT_MARGIN : integer := 8;
	constant TOP_MARGIN  : integer := 8;
	constant BLOCK_SIZE  : integer := 20;
	
	signal query_cell_r  : block_pos_type;
	--altri segnali di cui avrete encessita'

begin

	QUERY_CELL <= query_cell_r;

	process(CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			FB_CLEAR         <= '0';
			FB_DRAW_RECT     <= '0';
			FB_DRAW_LINE     <= '0';
			FB_FILL_RECT     <= '0';
			FB_FLIP          <= '0';
			query_cell_r.col <= 0;
			query_cell_r.row <= 0;

		elsif (rising_edge(CLOCK)) then
		
			FB_CLEAR       <= '0';
			FB_DRAW_RECT   <= '0';
			FB_DRAW_LINE   <= '0';
			FB_FILL_RECT   <= '0';
			FB_FLIP        <= '0';
			
			--Completare qui' 
			
		end if;
	end process;
	
end architecture;
