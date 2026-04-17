library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity comparator_ge is
    generic (
        DATA_WIDTH : integer := 9
    );
    port (
        A       : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); -- Es: Credito Attuale
        B       : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); -- Es: Prezzo
        A_ge_B  : out STD_LOGIC
    );
end comparator_ge;

architecture Behavioral of comparator_ge is
begin
    A_ge_B <= '1' when unsigned(A) >= unsigned(B) else '0';
end Behavioral;
