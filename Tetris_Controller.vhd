library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.tetris_package.all;

entity Tetris_Controller is
	port
	(
		CLOCK           : in  std_logic;
		RESET_N         : in  std_logic;
		TIME_10MS       : in  std_logic;
		
		BUTTON_LEFT     : in  std_logic;
		BUTTON_RIGHT    : in  std_logic;
		BUTTON_DOWN     : in  std_logic;
		BUTTON_ROTATE   : in  std_logic;
		-- Connections with Tetris_Datapath
		CAN_MOVE_LEFT   : in  std_logic;
		CAN_MOVE_RIGHT  : in  std_logic;
		CAN_MOVE_DOWN   : in  std_logic;
		CAN_ROTATE      : in  std_logic;
		ROW_IS_COMPLETE : in  std_logic;
		CLEAR           : out std_logic;
		MOVE_DOWN       : out std_logic;
		MOVE_LEFT       : out std_logic;
		MOVE_RIGHT      : out std_logic;
		ROTATE          : out std_logic;
		MERGE           : out std_logic;
		REMOVE_ROW  	: out std_logic;
		ROW_INDEX       : out integer range 0 to (BOARD_ROWS-1);
		NEW_PIECE       : out std_logic;
		NEW_PIECE_TYPE  : out piece_type;
		-- Connections with View
		REDRAW          : out std_logic
	);

end entity;


architecture RTL of Tetris_Controller is
	constant STANDARD_FALL_SPEED  : integer := 50;
	constant FAST_FALL_SPEED      : integer := 10;
	constant MOVEMENT_SPEED       : integer := 20;

	signal   fall_speed           : integer range 1 to 100;
	signal   time_to_next_fall    : integer range 0 to (fall_speed'high-1);
	signal   move_piece_down      : std_logic;

	signal   time_to_next_move    : integer range 0 to MOVEMENT_SPEED-1;
	signal   move_time            : std_logic;	

	type     row_check_state_type is (IDLE, CHECKING_ROW, WAIT_ROW_REMOVAL);
	signal   row_check_req        : std_logic;
	signal   row_check_ack        : std_logic;
	signal   row_check_counter    : integer range 0 to BOARD_ROWS-1;
	signal   row_check_state      : row_check_state_type;
	
	signal   random_piece         : piece_type;
	signal   rnd_count_r          : integer range 0 to 6;
begin

	CLEAR <= '0';
	ROW_INDEX <= row_check_counter;
	
	fall_speed <=  FAST_FALL_SPEED when (BUTTON_DOWN = '1')
	               else STANDARD_FALL_SPEED;
				   
				   
	TimedFall : process(CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			time_to_next_fall <= 0;
			move_piece_down   <= '0';
		elsif rising_edge(CLOCK) then
			move_piece_down <= '0';
			
			if (TIME_10MS = '1') then
				if (time_to_next_fall = 0) then
					time_to_next_fall <= fall_speed - 1;
					move_piece_down   <= '1';
				else
					time_to_next_fall <= time_to_next_fall - 1;
				end if;
			end if;
		end if;
	end process;
			
			
	TimedMove : process(CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			time_to_next_move  <= 0;
			move_time          <= '0';
		elsif rising_edge(CLOCK) then
			move_time <= '0';
			
			if (TIME_10MS = '1') then
				if (time_to_next_move = 0) then
					time_to_next_move  <= MOVEMENT_SPEED - 1;
					move_time          <= '1';
				else
					time_to_next_move  <= time_to_next_move - 1;
				end if;
			end if;
		end if;
	end process;
	
	
	Controller_RTL : process (CLOCK, RESET_N)
	begin
		if (RESET_N = '0') then
			MERGE           <= '0';
			NEW_PIECE       <= '0';
			MOVE_DOWN       <= '0';
			MOVE_LEFT       <= '0';
			MOVE_RIGHT      <= '0';
			ROTATE          <= '0';		
			REDRAW          <= '0';
			row_check_req   <= '0';				
		elsif rising_edge(CLOCK) then
			MERGE           <= '0';
			NEW_PIECE       <= '0';
			MOVE_DOWN       <= '0';
			MOVE_LEFT       <= '0';
			MOVE_RIGHT      <= '0';
			ROTATE          <= '0';		
			REDRAW          <= '0';
			row_check_req   <= '0';	
		
			if (move_piece_down = '1') then
				if (CAN_MOVE_DOWN = '1') then
					MOVE_DOWN       <= '1';
					REDRAW          <= '1';
				else 
					MERGE           <= '1';
					NEW_PIECE       <= '1';
					NEW_PIECE_TYPE  <= random_piece;
					row_check_req   <= '1';	
				end if;
			elsif (move_time = '1') then
				if (BUTTON_ROTATE = '1' and CAN_ROTATE = '1') then
					ROTATE    <= '1';
					REDRAW    <= '1';
				elsif (BUTTON_LEFT = '1' and CAN_MOVE_LEFT = '1') then
					MOVE_LEFT <= '1';
					REDRAW    <= '1';
				elsif (BUTTON_RIGHT = '1' and CAN_MOVE_RIGHT = '1') then
					MOVE_RIGHT <= '1';
					REDRAW     <= '1';
				end if;				
			end if;
			
			if (row_check_ack = '1') then
				REDRAW <= '1';
			end if;
		end if;
	end process;
	
	
	Row_check : process(CLOCK, RESET_N)
	begin
	
		if (RESET_N = '0') then
			REMOVE_ROW            <= '0';
			row_check_state       <= IDLE;
			row_check_ack         <= '0';
			
		elsif rising_edge(CLOCK) then
			REMOVE_ROW        <= '0';
			row_check_ack     <= '0';
			
			case (row_check_state) is
			
				when IDLE =>
					if (row_check_req = '1') then
						row_check_state   <= CHECKING_ROW;
						row_check_counter <= BOARD_ROWS - 1;
					end if;
					
				when CHECKING_ROW =>
					if (ROW_IS_COMPLETE = '1') then
						REMOVE_ROW        <= '1';
						row_check_state   <= WAIT_ROW_REMOVAL;
					elsif (row_check_counter /= 0) then
						row_check_counter <= row_check_counter - 1;
					else
						row_check_state   <= IDLE;
						row_check_ack     <= '1';
					end if;
				
				when WAIT_ROW_REMOVAL =>
					row_check_state   <= CHECKING_ROW;
				
			end case;
		end if;
	end process;
	
	rand_shape : process(RESET_N, CLOCK)
	begin
		if (RESET_N = '0') then
			rnd_count_r <= 0;
		elsif (rising_edge(CLOCK)) then
			if(TIME_10MS = '1' or BUTTON_RIGHT = '1' or BUTTON_LEFT = '1' or BUTTON_ROTATE = '1') then
				if(rnd_count_r /= rnd_count_r'high-1) then
					rnd_count_r <= rnd_count_r + 1;
				else
					rnd_count_r <= 0;
				end if;
			end if;			
		end if;
	end process;
	

	with rnd_count_r select random_piece <= 
		PIECE_T when 0,
		PIECE_SQUARE when 1,
		PIECE_STICK when 2,
		PIECE_L when 3,
		PIECE_LR when 4,
		PIECE_DOG_L when 5,
		PIECE_DOG_R when 6;
		
end architecture;
