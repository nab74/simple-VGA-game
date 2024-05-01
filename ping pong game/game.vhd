----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:24:39 11/08/2023 
-- Design Name: 
-- Module Name:    game - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity project2 is
    Port ( clk : in  STD_LOGIC;
           SW0 : in  STD_LOGIC;
           SW1 : in  STD_LOGIC;
           SW2 : in  STD_LOGIC;
           SW3 : in  STD_LOGIC;
           H : out  STD_LOGIC;
           V : out  STD_LOGIC;
           DAC_CLK : out  STD_LOGIC;
           Rout : out  STD_LOGIC_VECTOR (7 downto 0);
           Gout : out  STD_LOGIC_VECTOR (7 downto 0);
           Bout : out  STD_LOGIC_VECTOR (7 downto 0));
end project2;

architecture Behavioral of project2 is

	----------------------
	-- VGA Known Parameters
	----------------------
	constant h_front_porch : integer := 16;
	constant h_complete_line : integer := 800;
	constant h_sync_pulse : integer := 96;
	constant v_front_porch : integer := 10;
	constant v_complete_frame : integer := 525;
	constant v_sync_pulse : integer := 2;
	-----------------------------
	-- Clock Generation Signals
	-----------------------------
	signal clk_div : STD_LOGIC := '0';
	signal clk_counter : integer := 0;
	signal clk_motion : STD_LOGIC := '0';
	--------------------------
	-- Pixel display signals
	--------------------------
	signal is_video_on : STD_LOGIC;
	signal h_counter : integer := 0;
	signal v_counter : integer := 0;
	signal p1_x : integer := 50;
	signal p1_y : integer := 360;
	signal p2_x : integer := 580;
	signal p2_y : integer := 60;
	signal ball_x : integer := 310;
	signal ball_y : integer := 230; -- center = (360, 240)
	signal h_dir : STD_LOGIC; -- 0 = right, 1 = left
	signal v_dir : STD_LOGIC; -- 0 = down,  1  = up
	
	begin

	----------------------------
	-- Clock Divider
	----------------------------
	process (clk)
	begin
		if (clk'Event and clk = '1') then
			clk_div <= NOT clk_div;
			if (clk_counter  = 100000) then
				clk_motion <= NOT clk_motion;
				clk_counter <= 0;
			else
				clk_counter <= clk_counter + 1;
			end if;
		end if;
	end process;

	------------------------
	-- Pixel Configuration
	------------------------
	process (clk_div, SW3)
	begin
		-- Reset Switch
		if (SW3 = '1') then
			h_counter <= 0;
			v_counter <= 0;
			H <= '1';
			V <= '0';
			is_video_on <= '0';
		else
			if (clk_div'Event and clk_div = '1') then
				-------------------------------------------
				-- Counter for pixel location calculation
				-------------------------------------------
				if (h_counter < h_complete_line - 1) then
					h_counter <= h_counter + 1;
				else
					h_counter <= 0;
				if (v_counter < v_complete_frame - 1) then
					v_counter <= v_counter + 1;
				else
					v_counter <= 0;
				end if;
				end if;
				-----------------------------------------
				-- Sync configuration
				-----------------------------------------
				-- Horizontal Sync
				if ((h_counter < 639 + h_front_porch) OR (h_counter >= 639 + h_front_porch + h_sync_pulse)) then
					H <= '1';
				else
					H <= '0';
				end if;
				-- Vertical Sync
				if ((v_counter < 479 + v_front_porch) OR (v_counter >= 479 + v_front_porch + v_sync_pulse)) then
					V <= '1';
				else
					V <= '0';
				end if;
				------------------------------------------
				-- Determine pixel avilability
				------------------------------------------
				if ((h_counter < 640) AND (v_counter < 480)) then
					is_video_on <= '1';
				else
					is_video_on <= '0';
				end if;
			end if;
		end if;
	end process;
	------------------
	-- Motion Update
	------------------
	process (clk_motion, SW0, SW2, p1_y, p2_y)
	begin
		if (clk_motion'Event and clk_motion = '1') then
			-----------------------------
			-- Update Player 1 location
			-----------------------------
			if (SW0 = '0') then
				if (p1_y < 360) then
					p1_y <= p1_y + 1;
				else
					p1_y <= 360;
				end if;
			else
				if (p1_y > 40) then
					p1_y <= p1_y - 1;
				else
					p1_y <= 40;
				end if;
			end if;
			-----------------------------
			-- Update Player 2 location
			-----------------------------
			if (SW2 = '0') then
				if (p2_y < 360) then
					p2_y <= p2_y + 1;
				else
					p2_y <= 360;
				end if;
			else
				if (p2_y > 40) then
					p2_y <= p2_y - 1;
				else
					p2_y <= 40;
				end if;
			end if;
			------------------------------
			-- Update direction
			------------------------------
			if ( ball_x >= p1_x and ball_x < p1_x + 10) then
				-- Change direction when hit the left player
				if ( ((ball_y >= p1_y) or (ball_y + 10 >= p1_y)) and ((ball_y < p1_y + 80) or (ball_y + 10 < p1_y + 80)) ) then
					h_dir <= '0';
				end if;
			elsif ( ball_x = 40 ) then
				-- Change direction when hit left boundary
				if ( (ball_y >= 40 and ball_y < 160) or (ball_y + 10 >= 360 and ball_y + 10 < 440) ) then
					h_dir <= '0';
				end if;
			elsif (ball_x + 10 > p2_x and ball_x + 10 <= p2_x + 10) then
				-- Change direction when hit the right player
				if ( ((ball_y >= p2_y) or (ball_y + 10 >= p2_y)) and ((ball_y < p2_y + 80) or (ball_y + 10 < p2_y + 80)) ) then
					h_dir <= '1';
				end if;
			elsif (ball_x + 10 = 600) then
				-- Change direction when hit right boundary
				if ( (ball_y >= 40 and ball_y < 160) or (ball_y + 10 >= 360 and ball_y + 10 < 440) ) then
					h_dir <= '1';
				end if;
			end if;
			if ( ball_y - 1 <= 40 ) then
				v_dir <= '1';
			elsif (ball_y + 11 >= 440) then
				v_dir <= '0';
			end if;
			-----------------------------
			-- Update ball location
			-----------------------------
			if ((ball_x > 0) and (ball_x + 10) < 639) then
				-- Horizontal
				if (h_dir = '0') then
					ball_x <= ball_x + 1;
				elsif (h_dir = '1') then
					ball_x <= ball_x - 1;
				end if;
				-- Vertical
				if (v_dir = '0') then
					ball_y <= ball_y - 1;
				elsif(v_dir = '1') then
					ball_y <= ball_y + 1;
				end if;
			else
				ball_x <= 300;
				ball_y <= 220;
			end if;
		end if;
	end process;
	-------------------------------- 
	-- Pixel Color Set
	--------------------------------
	process (is_video_on)
	begin
		if (is_video_on = '0') then
			Rout <= (others => '0');
			Gout <= (others => '0');
			Bout <= (others => '0');
		else
			if (h_counter >= 20 and h_counter < 640 - 20 and v_counter >=20 and v_counter < 460) then
				if ( v_counter < 40 or v_counter >= 440) then
					Rout <= (others => '1');  -- Display white for top & bottom border
					Gout <= (others => '1');
					Bout <= (others => '1');
				elsif (((h_counter < 40) OR (h_counter >= 640 - 40)) and (v_counter < 160 or v_counter >= 320)) then
					Rout <= (others => '1');  -- Display white for left & right border
					Gout <= (others => '1');
					Bout <= (others => '1');
				elsif ((h_counter >= ball_x and h_counter < ball_x + 10) and (v_counter >= ball_y and v_counter < ball_y + 10) )then
					Rout <= (others => '1');   -- Color Ball inside play field (gate + border)
					Gout <= (others => '1');
					Bout <= (others => '0');
				elsif ((h_counter >= p1_x and h_counter < p1_x + 10) and (v_counter >= p1_y and v_counter < p1_y + 80) )then
					Rout <= (others => '0');   -- Color Player 1
					Gout <= (others => '0');
					Bout <= (others => '1');
				elsif ((h_counter >= p2_x and h_counter < p2_x + 10) and (v_counter >= p2_y and v_counter < p2_y + 80) )then
					Rout <= (others => '1');   -- Color Player 2
					Gout <= (others => '0');
					Bout <= (others => '1');
				elsif (v_counter >= 40 and v_counter < 440 and h_counter = 320) then
					Rout <= (others => '1');   -- Color center line
					Gout <= (others => '1');
					Bout <= (others => '1');
				else
					Rout <= (others => '0');	-- Color background
					Gout <= (others => '1');
					Bout <= (others => '0');
				end if;
			elsif ((h_counter >= ball_x and h_counter < ball_x + 10) and (v_counter >= ball_y and v_counter < ball_y + 10) )then
				Rout <= (others => '1');   -- Color Ball
				Gout <= (others => '0');
				Bout <= (others => '0');
			else
				Rout <= (others => '0');	-- Color background
				Gout <= (others => '1');
				Bout <= (others => '0');
			end if;
		end if;
	end process;
	
	DAC_CLK <= clk_div;

end Behavioral;