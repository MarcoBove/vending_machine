library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


-- aggiungere comparatore
-- problema sincronizzare a colpi di clock con la fsm
entity adder_subtractor is
    generic ( 
        DATA_WIDTH : INTEGER := 9
    );
    port (
        A         : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        B         : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        operation : in  STD_LOGIC; -- 0 = somma, 1 = sottrazione
        result    : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        Cout      : out STD_LOGIC
    );
end entity;

architecture Behavioral of adder_subtractor is

    signal A_u, B_u : unsigned(DATA_WIDTH downto 0);
    signal RES_u    : unsigned(DATA_WIDTH downto 0);

begin

    -- estensione a DATA_WIDTH+1 bit per carry
    A_u <= '0' & unsigned(A);
    B_u <= '0' & unsigned(B);

    -- ADD/SUB con when-else
    RES_u <= (A_u + B_u) when operation = '0' else
             (A_u - B_u);

    result <= std_logic_vector(RES_u(DATA_WIDTH-1 downto 0));
    Cout   <= RES_u(DATA_WIDTH);

end architecture;