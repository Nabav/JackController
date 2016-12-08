library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Jack_Controller_Main_State_Machine is
	port ( 
		clk : in std_logic;
		DIR_RS485 : out std_logic;
		Tx_Start : out std_logic;
		Tx_Frame_Type : out std_logic_vector(1 downto 0);
		Tx_Jack_Nember : out std_logic_vector(2 downto 0);
		Tx_Parameter_Address : out std_logic_vector(7 downto 0);
		Tx_Parameter_Value : out std_logic_vector(15 downto 0);
		Tx_Busy : in std_logic;
		Rx_Ready : in std_logic;
		Rx_Frame_Type : in std_logic_vector(1 downto 0);
		Rx_Jack_Nember : in std_logic_vector(2 downto 0);
		Rx_Parameter_Address : in std_logic_vector(7 downto 0);
		Rx_Parameter_Value : in std_logic_vector(15 downto 0);
		Parameter_Bank_Jack_ID : in std_logic_vector(2 downto 0);
		Parameter_Bank_Read_Request : out std_logic;
		Parameter_Bank_Read_Address : out std_logic_vector(7 downto 0);
		Parameter_Bank_Read_Response : in std_logic;
		Parameter_Bank_Read_Data : in std_logic_vector(15 downto 0);
		Parameter_Bank_Write_Request : out std_logic;
		Parameter_Bank_Write_Address : out std_logic_vector(7 downto 0);
		Parameter_Bank_Write_Data : out std_logic_vector(15 downto 0);
		Parameter_Bank_Write_Done : in std_logic
	);
end Jack_Controller_Main_State_Machine;

architecture Behavioral of Jack_Controller_Main_State_Machine is
	constant max_timeout : integer := 3000;
	type FSM_state_type is (idle, decode,
							write_parameter, wait_for_write_done,
							read_parameter, wait_for_read_response, transmit_read_response, wait_for_transmit_read_response_done
							);
	signal state : FSM_state_type := idle;
begin
	DIR_RS485 <= Tx_Busy;
	
	Main_FSM: process(clk)
		variable timeout_counter : integer range 0 to max_timeout := 0;
		variable Tx_Busy_old : std_logic := '0';
		variable Rx_Ready_old : std_logic := '0';
		variable Parameter_Bank_Write_Done_old : std_logic := '0';
		variable Parameter_Bank_Read_Response_old : std_logic := '0';
	begin
		if rising_edge(clk) then
			case state is
				when idle =>
					timeout_counter := 0;
					Tx_Start <= '0';
					Parameter_Bank_Read_Request <= '0';
					Parameter_Bank_Write_Request <= '0';
					if (Rx_Ready_old = '0' and Rx_Ready = '1') then
						state <= decode;
					end if;
				when decode =>
					if (Rx_Frame_Type = "01" and ((Rx_Jack_Nember = Parameter_Bank_Jack_ID) or (Rx_Jack_Nember = "111"))) then
						Parameter_Bank_Write_Address <= Rx_Parameter_Address;
						Parameter_Bank_Write_Data <= Rx_Parameter_Value;
						state <= write_parameter;
					elsif (Rx_Frame_Type = "10" and (Rx_Jack_Nember = Parameter_Bank_Jack_ID)) then
						Parameter_Bank_Read_Address <= Rx_Parameter_Address;
						state <= read_parameter;
					else
						state <= idle;
					end if;
				when write_parameter =>
					Parameter_Bank_Write_Request <= '1';
					state <= wait_for_write_done;
				when wait_for_write_done =>
					timeout_counter := timeout_counter + 1;
					if ((Parameter_Bank_Write_Done_old = '0' and Parameter_Bank_Write_Done = '1') or (timeout_counter = max_timeout)) then
						state <= idle;
						timeout_counter := 0;
					end if;
				when read_parameter =>
					Parameter_Bank_Read_Request <= '1';
					state <= wait_for_read_response;
				when wait_for_read_response =>
					timeout_counter := timeout_counter + 1;
					if (Parameter_Bank_Read_Response_old = '0' and Parameter_Bank_Read_Response = '1') then
						Tx_Frame_Type <= "11";
						Tx_Jack_Nember <= Rx_Jack_Nember;
						Tx_Parameter_Address <= Rx_Parameter_Address;
						Tx_Parameter_Value <= Parameter_Bank_Read_Data;
						state <= transmit_read_response;
					elsif (timeout_counter = max_timeout) then
						state <= idle;
						timeout_counter := 0;
					end if;
				when transmit_read_response =>
					Tx_Start <= '1';
					state <= wait_for_transmit_read_response_done;
				when wait_for_transmit_read_response_done =>
					timeout_counter := timeout_counter + 1;
					if ((Tx_Busy_old = '0' and Tx_Busy = '1') or (timeout_counter = max_timeout)) then
						state <= idle;
						timeout_counter := 0;
					end if;
			end case;
			Tx_Busy_old := Tx_Busy;
			Rx_Ready_old := Rx_Ready;
			Parameter_Bank_Read_Response_old := Parameter_Bank_Read_Response;
			Parameter_Bank_Write_Done_old := Parameter_Bank_Write_Done;
		end if;
	end process;
end Behavioral;