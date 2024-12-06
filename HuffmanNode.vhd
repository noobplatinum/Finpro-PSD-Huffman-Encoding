
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HuffmanProcessor is
    Port (
        clk         : in  STD_LOGIC;
        reset       : in  STD_LOGIC;
        sort_ready  : out STD_LOGIC;
        sorted_char : out STD_LOGIC_VECTOR(7 downto 0);
        sorted_freq : out INTEGER;
        done        : out STD_LOGIC
    );
end HuffmanProcessor;

architecture Behavioral of HuffmanProcessor is
    -- NodeGenerator component
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

    -- NodeSorter component
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

    -- Internal signals
    signal gen_node_ready : STD_LOGIC;
    signal gen_node_char  : STD_LOGIC_VECTOR(7 downto 0);
    signal gen_node_freq  : INTEGER;
    signal gen_done       : STD_LOGIC;
    signal sort_done_int  : STD_LOGIC;

    type state_type is (gen_phase, sort_phase, done_state);
    signal state : state_type := gen_phase;

begin
    -- Instantiate NodeGenerator
    node_gen: NodeGenerator port map (
        clk        => clk,
        reset      => reset,
        node_ready => gen_node_ready,
        node_char  => gen_node_char,
        node_freq  => gen_node_freq,
        done       => gen_done
    );

    -- Instantiate NodeSorter
    node_sort: NodeSorter port map (
        clk         => clk,
        reset       => reset,
        node_ready  => gen_node_ready,
        node_char   => gen_node_char,
        node_freq   => gen_node_freq,
        input_done  => gen_done,
        sort_ready  => sort_ready,
        sorted_char => sorted_char,
        sorted_freq => sorted_freq,
        sort_done   => sort_done_int
    );

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