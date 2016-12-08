library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity Debounce is
	generic (
		depth : in natural
	);
	port ( 
		clk : in std_logic;
		original : in std_logic;
		filtered : out std_logic
	);
end Debounce;

architecture Behavioral of Debounce is
begin
	process(clk)
		variable debounce_sr : std_logic_vector(depth-1 downto 0) := (others => '1');
	begin
		if rising_edge(clk) then
			if (debounce_sr = 0) then
				filtered <= '0';
			elsif (debounce_sr = (2**depth - 1)) then
				filtered <= '1';
			end if;
			debounce_sr := debounce_sr(depth - 2 downto 0) & original;
		end if;
	end process;
end Behavioral;

