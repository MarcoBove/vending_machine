library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity coin_encoder is
    generic (
        DATA_WIDTH : integer := 9
    );
    port (
        coin_50c_p : in  std_logic;
        coin_1e_p  : in  std_logic;
        coin_2e_p  : in  std_logic;
        coin_val   : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end coin_encoder;

architecture Behavioral of coin_encoder is
begin
    -- Assegnazione condizionale per codificare l'ingresso
    coin_val <= std_logic_vector(to_unsigned(50, DATA_WIDTH))  when coin_50c_p = '1' else
                std_logic_vector(to_unsigned(100, DATA_WIDTH)) when coin_1e_p = '1'  else
                std_logic_vector(to_unsigned(200, DATA_WIDTH)) when coin_2e_p = '1'  else
                (others => '0');
end Behavioral;
