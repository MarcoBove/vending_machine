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
    signal credit_ok_sig                : STD_LOGIC;
    signal update_credit_sig            : STD_LOGIC;               
    signal clear_credit_sig             : STD_LOGIC;                    
    signal add_sup_operation_sig        : STD_LOGIC;    
    signal mux_sel_sig                  : STD_LOGIC;                       
    signal en_dispense_item_sig         : STD_LOGIC;                
    signal en_change_sig                : STD_LOGIC;

    signal current_credit_sig           : STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);



    --dichiarazione componenti

    component mux_2x1 is
        generic  (
            DATA_WIDTH : integer := 9
        );
        port (
            in_0 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);  --Moneta
            in_1 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);  --Prezzo
            sel  : in STD_LOGIC;
            m_out  : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
    end component;


    component ROM_price is
        generic(
            DATA_WIDTH : integer := 9; -- fino a 500 centesimi
            BUTTON_NUM : integer := 4  -- pulsanti 0..9
        );
        port (
            button_i : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0);
            price_o  : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
        end component;


    component finite_state_machine is
    
        generic (
        -- Range massimo credito (es. fino a 500c = 5 euro)
            MAX_CREDIT : integer := 9;
            BUTTON_NUM : integer := 4
        );
        port (
            CLK             : in  std_logic;
        aresetn             : in  std_logic; -- Reset asincrono attivo basso
        
        -- Ingressi: Monete 
        -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
        coin_50c_p_in      : in  std_logic; 
        coin_1e_p_in       : in  std_logic; 
        coin_2e_p_in       : in  std_logic; 


        -- Ingressi: Tastierino Numerico (0..9) e  OK e C
        btn_num_in         : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0); -- Codice prodotto
        btn_ok_p_in        : in  std_logic; -- Tasto OK (conferma)
        btn_c_p_in         : in  std_logic; -- Tasto C (cancella)


        -- Ingressi controllo
        credit_ok_in     : in std_logic; -- uscita comparatore

    
        -- Uscite 
        credit_insufficient_out : out std_logic;

        --Uscite controllo
        update_credit_out : out std_logic; --se è stato aggiornato il credito
        clear_credit_out : out std_logic; --azzera il credito
        add_sup_operation_out : out std_logic; --seleziona somma o sottrazione
        mux_sel_out : out std_logic; --seleziona moneta o prezzo
        en_dispense_item_out : out std_logic; --eroga se è 1
        en_change_out : out std_logic; --dai resto se è 1
        
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
            clr      : in  STD_LOGIC;
            en       : in  STD_LOGIC;
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

    component coin_encoder is
        generic (
            DATA_WIDTH : integer := 9
        );
        port (
            coin_50c_p : in  std_logic;
            coin_1e_p  : in  std_logic;
            coin_2e_p  : in  std_logic;
            coin_val   : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
    end component;

    component comparator_ge is
        generic (
            DATA_WIDTH : integer := 9
        );
        port (
            A       : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); -- Es: Credito Attuale
            B       : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); -- Es: Prezzo
            A_ge_B  : out STD_LOGIC
        );
    end component;

    component output_gate is
        generic (
            DATA_WIDTH : integer := 9
        );
        port (
            data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
            enable   : in  STD_LOGIC; -- Controllato dalla FSM
            data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
    end component;





begin

    FSM: finite_state_machine
        generic map (
            MAX_CREDIT => MAX_CREDIT,
            BUTTON_NUM => BUTTON_NUM
        )
        port map (
            CLK                     => CLK,
            aresetn                 => areset_n,

            coin_50c_p_in           => coin50_p,
            coin_1e_p_in            => coin_1e_p,
            coin_2e_p_in            => coin_2e_p,

            btn_num_in              => btn_num,
            btn_ok_p_in             => btn_ok_p,
            btn_c_p_in              => btn_c_p,

            -- Ingressi controllo
            credit_ok_in            => credit_ok_sig,
           
           
            credit_insufficient_out => credit_insufficient_out,

        --Uscite controllo
            update_credit_out       => update_credit_sig,             --se è stato aggiornato il credito
            clear_credit_out        => clear_credit_sig,              --azzera il credito
            add_sup_operation_out   => add_sup_operation_sig,              --seleziona somma o sottrazione
            mux_sel_out             => mux_sel_sig,              --seleziona moneta o prezzo
            en_dispense_item_out    => en_dispense_item_sig,              --eroga se è 1
            en_change_out           => en_change_sig              --dai resto se è 1
    );

    CREDIT_REGISTER : register
        generic map (
            DATA_WIDTH => MAX_CREDIT,
            RESET_VAL  => (others => '0')
        );
        port map (
            clk      => CLK,
            areset_n => areset_n,
            clr      => clear_credit_sig,
            en       => update_credit_sig, --questo non sono sicuro
            d        => current_credit_sig, --da controllare
            q        => current_credit_sig  --da controllare
        );


    ADDER_SUB : adder_subtractor
        generic map ( 
            DATA_WIDTH => MAX_CREDIT --9
        );
        port map(
            A         =>   
            B         => 
            operation => add_sup_operation_sig,
            result    => current_credit_sig,
            Cout      => '0'
        );
    
    ROM : ROM_price 
        generic map(
            DATA_WIDTH => MAX_CREDIT, --9 -- fino a 500 centesimi
            BUTTON_NUM => BUTTON_NUM  -- pulsanti 0..9
        );
        port map (
            button_i => btn_num,
            price_o  => 
        );

    MUX_ADDER_IN : mux_2x1
        generic map(
            DATA_WIDTH => MAX_CREDIT  --9
        );
        port map (
            in_0   =>  --Moneta
            in_1   =>   --Prezzo
            sel    => 
            m_out  => 
        );

    ENCODER : coin_encoder 
        generic map(
            DATA_WIDTH => MAX_CREDIT --9
        );
        port map(
            coin_50c_p =>
            coin_1e_p  => 
            coin_2e_p  => 
            coin_val   => 
        );
    

    COMPARATOR: comparator_ge 
        generic map (
            DATA_WIDTH => DATA_WIDTH --9
        );
        port map (
            A       =>  -- Es: Credito Attuale
            B       =>  -- Es: Prezzo
            A_ge_B  => 
        );
    
    OUTPUT_GATE: output_gate 
        generic map (
            DATA_WIDTH => DATA_WIDTH     --9
        );
        port map(
            data_in  => 
            enable   =>
            data_out =>
        );


end architecture;