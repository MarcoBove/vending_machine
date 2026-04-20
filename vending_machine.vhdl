library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity vending_machine is
    generic (
        MAX_CREDIT_BIT : integer := 9;  
        BUTTON_NUM_BIT : integer := 4
    );
    port (
        CLK             : in  std_logic;
        areset_n         : in  std_logic; -- Reset asincrono
        
        -- Ingressi: Monete 
        -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
        coin_50c_in      : in  std_logic; 
        coin_1e_in       : in  std_logic; 
        coin_2e_in       : in  std_logic; 


        -- Ingressi: Tastierino Numerico 
        btn_num_in         : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0);
        btn_ok_in        : in  std_logic; -- Tasto OK (conferma)
        btn_c_in         : in  std_logic; -- Tasto C (cancella)
        
        -- Uscite 
        current_credit_out      : out STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
        credit_insufficient_out : out std_logic;
        dispense_item_out       : out  STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
        dispense_change_out     : out  STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
    );
end vending_machine;


architecture Structural of vending_machine is
    
    --segnali interni
    signal credit_ok                    : STD_LOGIC;   

    --uscite FSM
    signal fsm_update_credit            : STD_LOGIC;               
    signal fsm_clear_credit             : STD_LOGIC;                    
    signal fsm_add_sub_operation        : STD_LOGIC;    
    signal fsm_mux_sel                  : STD_LOGIC;                       
    signal fsm_en_dispense_item         : STD_LOGIC;                
    signal fsm_en_change                : STD_LOGIC;

    signal current_credit           : STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
    signal adder_result             : STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
    signal adder_B                  : STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
    signal coin_val                 : STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
    signal price_val                : STD_LOGIC_VECTOR(MAX_CREDIT_BIT-1 downto 0);
    



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
            BUTTON_NUM_BIT : integer := 4  -- pulsanti 0..9
        );
        port (
            button_i : in  STD_LOGIC_VECTOR(BUTTON_NUM_BIT-1 downto 0);
            price_o  : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
        end component;


    component finite_state_machine is
    
        generic (
        -- Range massimo credito (es. fino a 500c = 5 euro)
            MAX_CREDIT_BIT : integer := 9;
            BUTTON_NUM_BIT : integer := 4
        );
        port (
                CLK             : in  std_logic;
            aresetn             : in  std_logic; -- Reset asincrono attivo basso
        
            -- Ingressi: Monete 
            -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
            coin_50c_in      : in  std_logic; 
            coin_1e_in       : in  std_logic; 
            coin_2e_in       : in  std_logic; 


            -- Ingressi: Tastierino Numerico (0..9) e  OK e C
            btn_num_in         : in  STD_LOGIC_VECTOR(BUTTON_NUM_BIT-1 downto 0); -- Codice prodotto
            btn_ok_in        : in  std_logic; -- Tasto OK (conferma)
            btn_c_in         : in  std_logic; -- Tasto C (cancella)


            -- Ingressi controllo
            credit_ok_in     : in std_logic; -- uscita comparatore

    
            -- Uscite 
            credit_insufficient_out : out std_logic;

            --Uscite controllo
            update_credit_out : out std_logic;        --se è stato aggiornato il credito
            clear_credit_out : out std_logic;         --azzera il credito
            add_sub_operation_out : out std_logic;    --seleziona somma o sottrazione
            mux_sel_out : out std_logic;              --seleziona moneta o prezzo
            en_dispense_item_out : out std_logic;     --eroga se è 1
            en_change_out : out std_logic;            --dai resto se è 1
        
        );
    end component;

    component register_en_clr is
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
            en   : in  STD_LOGIC; -- Controllato dalla FSM
            data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
        );
    end component;





begin

    current_credit_out <= current_credit_sig;

    FSM_INST: finite_state_machine
        generic map (
            MAX_CREDIT_BIT => MAX_CREDIT_BIT,
            BUTTON_NUM_BIT => BUTTON_NUM_BIT
        )
        port map (
            CLK                     => CLK,
            areset_n                => areset_n,

            coin_50c_in           => coin_50c_in,
            coin_1e_in            => coin_1e_in,
            coin_2e_in            => coin_2e_in,

            btn_num_in              => btn_num_in,
            btn_ok_in             => btn_ok_in,
            btn_c_in              => btn_c_in,

            -- Ingressi controllo
            credit_ok_in            => credit_ok,
           
           
            credit_insufficient_out => credit_insufficient_out, 

            --Uscite controllo
            update_credit_out       => fsm_update_credit,             --se è stato aggiornato il credito
            clear_credit_out        => fsm_clear_credit,              --azzera il credito
            add_sub_operation_out   => fsm_add_sub_operation,         --seleziona somma o sottrazione
            mux_sel_out             => fsm_mux_sel,                   --seleziona moneta o prezzo
            en_dispense_item_out    => fsm_en_dispense_item,          --eroga se è 1
            en_change_out           => fsm_en_change                  --dai resto se è 1
    );

    CREDIT_REGISTER_INST : register_en_clr
        generic map (
            DATA_WIDTH => MAX_CREDIT_BIT,
            RESET_VAL  => (others => '0')
        )
        port map (
            clk      => CLK,
            areset_n => areset_n,
            clr      => fsm_clear_credit,
            en       => fsm_update_credit,
            d        => adder_result,
            q        => current_credit  
        );


    ADDER_SUB_INST : adder_subtractor  
        generic map ( 
            DATA_WIDTH => MAX_CREDIT_BIT --9
        )
        port map(
            A         => current_credit  
            B         => adder_B
            operation => fsm_add_sub_operation,
            result    => adder_result,
            Cout      => open 
        );
    
    ROM_INST : ROM_price 
        generic map(
            DATA_WIDTH => MAX_CREDIT_BIT, 
            BUTTON_NUM => BUTTON_NUM_BIT  -- pulsanti 0..9
        )
        port map (
            button_i => btn_num_in,
            price_o  => price_val
        );

    MUX_ADDER_IN_INST : mux_2x1
        generic map(
            DATA_WIDTH => MAX_CREDIT_BIT  --9
        )
        port map (
            in_0   =>  coin_val,   --Moneta
            in_1   =>  price_val,--Prezzo
            sel    =>  fsm_mux_sel,
            m_out  =>  adder_b
        );

    ENCODER_INST : coin_encoder 
        generic map(
            DATA_WIDTH => MAX_CREDIT_BIT --9
        )
        port map(
            coin_50c_p => coin_50c_in,
            coin_1e_p  => coin_1e_in,
            coin_2e_p  => coin_2e_in,
            coin_val   => coin_val
        );
    

    COMPARATOR_INST: comparator_ge 
        generic map (
            DATA_WIDTH => MAX_CREDIT_BIT --9
        )
        port map (
            A       =>  current_credit,   -- Es: Credito Attuale
            B       =>  price_val,         -- Es: Prezzo
            A_ge_B  =>  credit_ok
        );
    
    DISPENSE_OUT_INST: output_gate 
        generic map (
            DATA_WIDTH => MAX_CREDIT_BIT     --9
        )
        port map(
            data_in  =>  price_val,
            en       =>  fsm_en_dispense_item,
            data_out =>  dispense_item_out
        );

    CHANGE_OUT_INST: output_gate 
        generic map (
            DATA_WIDTH => MAX_CREDIT_BIT     --9
        )
        port map(
            data_in  =>  current_credit,
            en       =>  fsm_en_change_out, 
            data_out =>  dispense_change_out
        );


end architecture;