library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity JackController is
	port ( 
		clk : in std_logic;
		RX_RS485 : in std_logic;
		TX_RS485 : out std_logic;
		DIR_RS485 : out std_logic;
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
end JackController;

architecture Behavioral of JackController is
	component Debounce is
		generic (
			depth : in natural
		);
		port ( 
			clk : in std_logic;
			original : in std_logic;
			filtered : out std_logic
		);
	end component;
	component Frame_Transmitter is
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
	end component;
	component Frame_Receiver is
		port ( 
			clk : in std_logic;
			RX_RS485 : in std_logic;
			Rx_Ready : out std_logic;
			Rx_Frame_Type : out std_logic_vector(1 downto 0);
			Rx_Jack_Nember : out std_logic_vector(2 downto 0);
			Rx_Parameter_Address : out std_logic_vector(7 downto 0);
			Rx_Parameter_Value : out std_logic_vector(15 downto 0)
		);
	end component;
	component Jack_Controller_Main_State_Machine is
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
	end component;

	signal Tx_Start : std_logic := '0';
	signal Tx_Frame_Type : std_logic_vector(1 downto 0) := (others => '0');
	signal Tx_Jack_Nember : std_logic_vector(2 downto 0) := (others => '0');
	signal Tx_Parameter_Address : std_logic_vector(7 downto 0) := (others => '0');
	signal Tx_Parameter_Value : std_logic_vector(15 downto 0) := (others => '0');
	signal Tx_Busy : std_logic := '0';
	signal RX_RS485_F : std_logic := '1';	
	signal Rx_Ready : std_logic := '0';
	signal Rx_Frame_Type : std_logic_vector(1 downto 0) := (others => '0');
	signal Rx_Jack_Nember : std_logic_vector(2 downto 0) := (others => '0');
	signal Rx_Parameter_Address : std_logic_vector(7 downto 0) := (others => '0');
	signal Rx_Parameter_Value : std_logic_vector(15 downto 0) := (others => '0');
begin
	RS485_Frame_Transmitter : Frame_Transmitter
		port map ( 
			clk => clk,
			TX_RS485 => TX_RS485,
			Tx_Start => Tx_Start,
			Tx_Frame_Type => Tx_Frame_Type,
			Tx_Jack_Nember => Tx_Jack_Nember,
			Tx_Parameter_Address => Tx_Parameter_Address,
			Tx_Parameter_Value => Tx_Parameter_Value,
			Tx_Busy => Tx_Busy
		);
	RX_RS485_Debounce_Filter : Debounce
		generic map (
			depth => 4
		)
		port map (
			clk => clk,
			original => RX_RS485,
			filtered => RX_RS485_F
		);
	 RS485_Frame_Receiver : Frame_Receiver
		port map ( 
			clk => clk,
			RX_RS485 => RX_RS485_F,
			Rx_Ready => Rx_Ready,
			Rx_Frame_Type => Rx_Frame_Type,
			Rx_Jack_Nember => Rx_Jack_Nember,
			Rx_Parameter_Address => Rx_Parameter_Address,
			Rx_Parameter_Value => Rx_Parameter_Value
		);
	Main_FSM : Jack_Controller_Main_State_Machine
		port map ( 
			clk => clk,
			DIR_RS485 => DIR_RS485,
			Tx_Start => Tx_Start,
			Tx_Frame_Type => Tx_Frame_Type,
			Tx_Jack_Nember => Tx_Jack_Nember,
			Tx_Parameter_Address => Tx_Parameter_Address,
			Tx_Parameter_Value => Tx_Parameter_Value,
			Tx_Busy => Tx_Busy,
			Rx_Ready => Rx_Ready,
			Rx_Frame_Type => Rx_Frame_Type,
			Rx_Jack_Nember => Rx_Jack_Nember,
			Rx_Parameter_Address => Rx_Parameter_Address,
			Rx_Parameter_Value => Rx_Parameter_Value,
			Parameter_Bank_Jack_ID => Parameter_Bank_Jack_ID,
			Parameter_Bank_Read_Request => Parameter_Bank_Read_Request,
			Parameter_Bank_Read_Address => Parameter_Bank_Read_Address,
			Parameter_Bank_Read_Response => Parameter_Bank_Read_Response,
			Parameter_Bank_Read_Data => Parameter_Bank_Read_Data,
			Parameter_Bank_Write_Request => Parameter_Bank_Write_Request,
			Parameter_Bank_Write_Address => Parameter_Bank_Write_Address,
			Parameter_Bank_Write_Data => Parameter_Bank_Write_Data,
			Parameter_Bank_Write_Done => Parameter_Bank_Write_Done
		);
end Behavioral;