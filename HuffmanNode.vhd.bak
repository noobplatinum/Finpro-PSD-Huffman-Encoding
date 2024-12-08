library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HuffmanProcessor is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        done        : out STD_LOGIC;
        root_index  : out INTEGER  -- Add output for final root index
    );
end HuffmanProcessor;

architecture Behavioral of HuffmanProcessor is
    -- NodeGenerator component (unchanged)
    component NodeGenerator is
        Port (
            clk        : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            node_ready : out STD_LOGIC;
            node_char  : out STD_LOGIC_VECTOR(7 downto 0);
            node_freq  : out INTEGER;
            done       : out STD_LOGIC
        );
    end component;

    -- NodeSorter component (unchanged)
    component NodeSorter is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            node_ready  : in  STD_LOGIC;
            node_char   : in  STD_LOGIC_VECTOR(7 downto 0);
            node_freq   : in  INTEGER;
            input_done  : in  STD_LOGIC;
            sort_ready  : out STD_LOGIC;
            sorted_char : out STD_LOGIC_VECTOR(7 downto 0);
            sorted_freq : out INTEGER;
            sort_done   : out STD_LOGIC
        );
    end component;

    -- Add NodeMerger component
    component NodeMerger is
        Port (
            clk         : in  STD_LOGIC;
            reset       : in  STD_LOGIC;
            sorted_char : in  STD_LOGIC_VECTOR(7 downto 0);
            sorted_freq : in  INTEGER;
            sort_ready  : in  STD_LOGIC;
            sort_done   : in  STD_LOGIC;
            merge_done  : out STD_LOGIC;
            root_index  : out INTEGER
        );
    end component;

    -- Internal signals (existing)
    signal gen_node_ready : STD_LOGIC;
    signal gen_node_char  : STD_LOGIC_VECTOR(7 downto 0);
    signal gen_node_freq  : INTEGER;
    signal gen_done       : STD_LOGIC;
    
    -- Add signals for NodeSorter to NodeMerger connection
    signal sort_ready_int : STD_LOGIC;
    signal sorted_char_int : STD_LOGIC_VECTOR(7 downto 0);
    signal sorted_freq_int : INTEGER;
    signal sort_done_int  : STD_LOGIC;
    signal merge_done_int : STD_LOGIC;
    signal root_index_int : INTEGER;

    -- Updated state machine
    type state_type is (gen_phase, sort_phase, merge_phase, done_state);
    signal state : state_type := gen_phase;

begin
    -- Instantiate NodeGenerator (unchanged)
    node_gen: NodeGenerator port map (
        clk        => clk,
        reset      => reset,
        node_ready => gen_node_ready,
        node_char  => gen_node_char,
        node_freq  => gen_node_freq,
        done       => gen_done
    );

    -- Instantiate NodeSorter (modified)
    node_sort: NodeSorter port map (
        clk         => clk,
        reset       => reset,
        node_ready  => gen_node_ready,
        node_char   => gen_node_char,
        node_freq   => gen_node_freq,
        input_done  => gen_done,
        sort_ready  => sort_ready_int,
        sorted_char => sorted_char_int,
        sorted_freq => sorted_freq_int,
        sort_done   => sort_done_int
    );

    -- Add NodeMerger instance
    node_merge: NodeMerger port map (
        clk         => clk,
        reset       => reset,
        sorted_char => sorted_char_int,
        sorted_freq => sorted_freq_int,
        sort_ready  => sort_ready_int,
        sort_done   => sort_done_int,
        merge_done  => merge_done_int,
        root_index  => root_index_int
    );

    -- Connect outputs
    root_index <= root_index_int;

    -- Control process
    process(clk, reset)
    begin
        if reset = '1' then
            state <= gen_phase;
            done <= '0';
        elsif rising_edge(clk) then
            case state is
                when gen_phase =>
                    if gen_done = '1' then
                        state <= sort_phase;
                    end if;

                when sort_phase =>
                    if sort_done_int = '1' then
                        state <= merge_phase;
                    end if;

                when merge_phase =>
                    if merge_done_int = '1' then
                        state <= done_state;
                        done <= '1';
                    end if;

                when done_state =>
                    done <= '1';

                when others =>
                    state <= done_state;
            end case;
        end if;
    end process;

end Behavioral;