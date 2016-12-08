library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Frame_Receiver is
	port ( 
		clk : in std_logic;
		RX_RS485 : in std_logic;
		Rx_Ready : out std_logic;
		Rx_Frame_Type : out std_logic_vector(1 downto 0);
		Rx_Jack_Nember : out std_logic_vector(2 downto 0);
		Rx_Parameter_Address : out std_logic_vector(7 downto 0);
		Rx_Parameter_Value : out std_logic_vector(15 downto 0)
	);
end Frame_Receiver;

architecture Behavioral of Frame_Receiver is
	constant f_ref : natural := 16384000;
	constant baudrate : natural := 512000;
	constant baudrate_prescaler : natural := f_ref / baudrate;
	signal baudrate_prescaler_counter : integer range 0 to baudrate_prescaler := 0;
	signal Rx_Buffer : std_logic_vector(39 downto 0) := (others => '0');
	signal checksum : std_logic_vector(7 downto 0) := (others => '0');
	signal bit_number : integer range 0 to 39 := 39;
	signal low_duration_counter : integer range 0 to 3 * baudrate_prescaler := 0;
	signal threshold : std_logic := '0';
	signal fresh_bit_received : std_logic := '0';
begin
	Low_State_Duration_Counter: process(clk)
		variable RX_RS485_old : std_logic := '0';
	begin
		if rising_edge(clk) then
			if (RX_RS485_old = '1' and RX_RS485 = '0') then
				low_duration_counter <= 0;
			elsif ((low_duration_counter < 3 * baudrate_prescaler) and (RX_RS485 = '0')) then
				low_duration_counter <= low_duration_counter + 1;				
			elsif (RX_RS485_old = '0' and RX_RS485 = '1') then
				Rx_Buffer <= Rx_Buffer(38 downto 0) & threshold;
				fresh_bit_received <= '1';
			end if;
			if (fresh_bit_received = '1') then
				fresh_bit_received <= '0';
				if (Rx_Buffer(39 downto 37) = "101" and checksum = x"00") then -- valid frame
					Rx_Ready <= '1';
					Rx_Frame_Type <= Rx_Buffer(36 downto 35);
					Rx_Jack_Nember <= Rx_Buffer(34 downto 32);
					Rx_Parameter_Address <= Rx_Buffer(31 downto 24);
					Rx_Parameter_Value <= Rx_Buffer(23 downto 8);
				else
					Rx_Ready <= '0';
				end if;
			end if;
			RX_RS485_old := RX_RS485;
		end if;
	end process;
	
	threshold <= '0' when (low_duration_counter < (3 * baudrate_prescaler / 2)) else '1';
	
	checksum <= Rx_Buffer(39 downto 32) +
				Rx_Buffer(31 downto 24) +
				Rx_Buffer(23 downto 16) +
				Rx_Buffer(15 downto 8) +
				Rx_Buffer(7 downto 0);

end Behavioral;