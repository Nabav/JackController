library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Frame_Transmitter is
	port ( 
		clk : in std_logic;
		TX_RS485 : out std_logic;
		Tx_Start : in std_logic;
		Tx_Frame_Type : in std_logic_vector(1 downto 0);
		Tx_Jack_Nember : in std_logic_vector(2 downto 0);
		Tx_Parameter_Address : in std_logic_vector(7 downto 0);
		Tx_Parameter_Value : in std_logic_vector(15 downto 0);
		Tx_Busy : out std_logic
	);
end Frame_Transmitter;

architecture Behavioral of Frame_Transmitter is
	constant f_ref : natural := 16384000;
	constant baudrate : natural := 512000;
	constant baudrate_prescaler : natural := f_ref / baudrate;
	signal baudrate_prescaler_counter : integer range 0 to baudrate_prescaler := 0;
	signal Tx_Buffer : std_logic_vector(39 downto 0) := (others => '0');
	signal checksum : std_logic_vector(7 downto 0) := (others => '0');
	type FSM_state_type is (idle, capture, send_low, send_bit, send_high, prepare_next_bit);
	signal state : FSM_state_type := idle;
	signal bit_number : integer range 0 to 39 := 39;
begin
	Frame_Tx_FSM: process(clk)
		variable Tx_Start_old : std_logic := '0';
	begin
		if rising_edge(clk) then
			if (baudrate_prescaler_counter >= baudrate_prescaler-1) then
				baudrate_prescaler_counter <= 0;
			else
				baudrate_prescaler_counter <= baudrate_prescaler_counter + 1;
			end if;
			case state is
				when idle =>
					TX_RS485 <= '1';
					Tx_Busy <= '0';
					bit_number <= 39;
					if (Tx_Start_old = '0' and Tx_Start = '1') then
						state <= capture;
					end if;
				when capture =>
					state <= send_low;
					Tx_Busy <= '1';
					Tx_Buffer(39 downto 32) <= "101" & Tx_Frame_Type & Tx_Jack_Nember;
					Tx_Buffer(31 downto 24) <= Tx_Parameter_Address;
					Tx_Buffer(23 downto 8) <= Tx_Parameter_Value;
				when send_low =>
					if (baudrate_prescaler_counter = 0) then
						TX_RS485 <= '0';
						state <= send_bit;
					end if;
				when send_bit =>
					if (baudrate_prescaler_counter = 0) then
						TX_RS485 <= not Tx_Buffer(bit_number);
						state <= send_high;
					end if;
				when send_high =>
					if (baudrate_prescaler_counter = 0) then
						TX_RS485 <= '1';
						state <= prepare_next_bit;
					end if;
				when prepare_next_bit =>
					if (bit_number > 0) then
						bit_number <= bit_number - 1;
						state <= send_low;
					else
						bit_number <= 39;
						state <= idle;
					end if;
			end case;
			Tx_Start_old := Tx_Start;
		end if;
	end process;
	
	checksum <= x"00" - (
				Tx_Buffer(39 downto 32) +
				Tx_Buffer(31 downto 24) +
				Tx_Buffer(23 downto 16) +
				Tx_Buffer(15 downto 8)
				);

	Tx_Buffer(7 downto 0) <= checksum;

end Behavioral;