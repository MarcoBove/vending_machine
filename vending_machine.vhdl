library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vending_machine is
     generic (
        -- Range massimo credito (es. fino a 500c = 5 euro)
        MAX_CREDIT : integer := 9;
        BUTTON_NUM : integer := 4
    );
    port (
        CLK             : in  std_logic;
        aresetn         : in  std_logic; -- Reset asincrono
        
        -- Ingressi: Monete 
        -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
        coin_50c_p      : in  std_logic; 
        coin_1e_p       : in  std_logic; 
        coin_2e_p       : in  std_logic; 


        -- Ingressi: Tastierino Numerico 
        btn_num         : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0);
        btn_ok_p        : in  std_logic; -- Tasto OK (conferma)
        btn_c_p         : in  std_logic; -- Tasto C (cancella)
        
        -- Uscite 
        current_credit_out      : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
        credit_insufficient_out : out std_logic;
        dispense_item_out       : out  STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
        dispense_change_out     : out  STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
    );
end vending_machine;


architecture Structural of vending_machine is
    --segnali interni
    


    --dichiarazione componenti
    component finite_state_machine is
    
        generic (
        -- Range massimo credito (es. fino a 500c = 5 euro)
            MAX_CREDIT : integer := 9;
            BUTTON_NUM : integer := 4
        );
        port (
            CLK             : in  std_logic;
            aresetn         : in  std_logic; -- Reset asincrono attivo basso
        
            -- Ingressi: Monete 
            -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
            coin_50c_p      : in  std_logic; 
            coin_1e_p       : in  std_logic; 
            coin_2e_p       : in  std_logic; 


            -- Ingressi: Tastierino Numerico (0..3 
            btn_num         : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0); -- Codice prodotto
            btn_ok_p        : in  std_logic; -- Tasto OK (conferma)
            btn_c_p         : in  std_logic; -- Tasto C (cancella)
        
            -- Uscite 
            current_credit_out      : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
            credit_insufficient_out : out std_logic;
            dispense_item_out       : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
            dispense_change_out     : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
        );
    end component;

    component register is
        generic (
            DATA_WIDTH : integer := 9; --500 sono 9 bit
            RESET_VAL  : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others => '0')
        );
        port (
            clk      : in  STD_LOGIC;
            areset_n : in  STD_LOGIC;
            d        : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
            q        : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
    end component;

    component adder_subtractor is
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
    end component;

begin

    FSM: finite_state_machine
        generic map (
            MAX_CREDIT => MAX_CREDIT,
            BUTTON_NUM => BUTTON_NUM
        )
        port map (
            CLK => CLK,
            aresetn => areset_n,

            coin_50c_p => coin50_p,
            coin_1e_p  => coin_1e_p,
            coin_2e_p  => coin_2e_p,

            btn_num => btn_num,
            btn_ok_p => btn_ok_p,
            btn_c_p  => btn_c_p,

            current_credit_out => current_credit_out,
            credit_insufficient_out => credit_insufficient_out,
            dispense_item_out => dispense_item_out,
            dispense_change_out => dispense_change_out
    );

    CREDIT_REGISTER : register
        generic map (
            DATA_WIDTH => MAX_CREDIT
            RESET_VAL  => 
        );
        port map (
            clk      => CLK,
            areset_n => areset_n,
            d        => 
            q        => 
        );




end architecture;