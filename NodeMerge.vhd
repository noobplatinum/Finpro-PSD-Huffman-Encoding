library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity NodeMerger is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        sorted_char   : in  std_logic_vector(7 downto 0);
        sorted_freq   : in  integer;
        sort_ready    : in  std_logic;
        sort_done     : in  std_logic;
        merge_done    : out std_logic;
        root_index    : out integer
    );
end NodeMerger;

architecture Behavioral of NodeMerger is
    -- Node type
    type node_type is record
        character    : std_logic_vector(7 downto 0);
        frequency    : integer;
        left_child   : integer;
        right_child  : integer;
        is_leaf      : boolean;
    end record;

    type state_type is (idle_state, load_state, sort_state, merge_state, done_state);
    file tree_file : text open write_mode is "HuffmanArray";

    procedure write_node_info(
        file f: text;
        index: in integer;
        node: in node_type) is
        variable l: line;
        variable temp_str: string(1 to 1);
    begin
        -- Write index
        write(l, integer'image(index), right, 1);
        write(l, string'(","));
        
        -- Write char
        if node.is_leaf then
            temp_str(1) := character'val(to_integer(unsigned(node.character)));
            write(l, temp_str, right, 1);
        else
            write(l, string'("-"), right, 1);
        end if;
        write(l, string'(","));
        
        -- Write frequency
        write(l, integer'image(node.frequency), right, 1);
        write(l, string'(","));
        
        -- Write left child
        write(l, integer'image(node.left_child), right, 1);
        write(l, string'(","));
        
        -- Write right child
        write(l, integer'image(node.right_child), right, 1);
        write(l, string'(","));
        
        -- Write leaf status
        write(l, boolean'image(node.is_leaf), right, 1);
        
        writeline(f, l);
    end procedure;

    constant NUM_LEAF_NODES : integer := 8;
    constant MAX_NODES      : integer := (2 * NUM_LEAF_NODES) - 1;

    type node_array is array(0 to MAX_NODES - 1) of node_type;
    type index_array is array(0 to MAX_NODES - 1) of integer;

    -- Init signal
    signal nodes : node_array := (others => (
        character => (others => '0'),
        frequency => 0,
        left_child => -1,
        right_child => -1,
        is_leaf => false
    ));
    
    signal sorted_indices : index_array := (others => 0);
    signal state : state_type := idle_state;  
    signal sorted_size : integer := 0;
    signal next_node_index : integer := 0;
    signal root_index_sig : integer := 0;
    signal received_first_node : boolean := false;
    signal write_complete : boolean := false;

    constant SHOW_DEBUG : boolean := true;

begin
    root_index <= root_index_sig;

    process(clk, reset)
        variable temp_index : integer;
        variable min1_index, min2_index : integer;
        variable i, j : integer;
        variable temp_indices : index_array;
        variable temp_node : node_type;
        variable temp_nodes : node_array;

    begin
        if reset = '1' then
            state <= idle_state;
            merge_done <= '0';
            sorted_size <= 0;
            next_node_index <= 0;
            root_index_sig <= 0;
            received_first_node <= false;
            -- Clear
            nodes <= (others => (
                character => (others => '0'),
                frequency => 0,
                left_child => -1,
                right_child => -1,
                is_leaf => false
            ));
            sorted_indices <= (others => 0);

        elsif rising_edge(clk) then
            case state is
                when idle_state =>
                    -- Accept when idle
                    if sort_ready = '1' then
                        if SHOW_DEBUG then
                            report "Idle state received node: Char = " & 
                                   character'val(to_integer(unsigned(sorted_char))) &
                                   ", Freq = " & integer'image(sorted_freq);
                        end if;

                        nodes(next_node_index).character <= sorted_char;
                        nodes(next_node_index).frequency <= sorted_freq;
                        nodes(next_node_index).is_leaf <= true;
                        sorted_indices(next_node_index) <= next_node_index;
                        
                        next_node_index <= next_node_index + 1;
                        received_first_node <= true;
                        state <= load_state;
                    end if;

                when load_state =>
                    if sort_ready = '1' then
                        if SHOW_DEBUG then
                            report "Loading node " & integer'image(next_node_index) & 
                                   ": Char = " & character'val(to_integer(unsigned(sorted_char))) &
                                   ", Freq = " & integer'image(sorted_freq);
                        end if;

                        nodes(next_node_index).character <= sorted_char;
                        nodes(next_node_index).frequency <= sorted_freq;
                        nodes(next_node_index).is_leaf <= true;
                        nodes(next_node_index).left_child <= -1;  -- Added
                        nodes(next_node_index).right_child <= -1; -- Added
                        sorted_indices(next_node_index) <= next_node_index;
                        next_node_index <= next_node_index + 1;
                    end if;

                    if sort_done = '1' then
                        sorted_size <= next_node_index;
                        state <= sort_state;
                        
                        if SHOW_DEBUG then
                            report "Total nodes loaded: " & integer'image(next_node_index);
                        end if;
                    end if;

                when sort_state =>
                    -- Sorting
                    temp_indices := sorted_indices;
                    
                    -- Bubble sort
                    for i in 0 to sorted_size - 2 loop
                        for j in 0 to sorted_size - i - 2 loop
                            if nodes(temp_indices(j)).frequency > nodes(temp_indices(j + 1)).frequency or
                            (nodes(temp_indices(j)).frequency = nodes(temp_indices(j + 1)).frequency and
                                temp_indices(j) > temp_indices(j + 1)) then
                                temp_index := temp_indices(j);
                                temp_indices(j) := temp_indices(j + 1);
                                temp_indices(j + 1) := temp_index;
                            end if;
                        end loop;
                    end loop;

                    if SHOW_DEBUG then
                        report "----------------------------------------";
                        report "Initial Sort:";
                        report "Array:";
                        for i in 0 to sorted_size - 1 loop
                            report "Index " & integer'image(i) & ": Node " & 
                                    integer'image(temp_indices(i)) & 
                                    " (Char = " & character'val(to_integer(unsigned(nodes(temp_indices(i)).character))) &
                                    ", Freq = " & integer'image(nodes(temp_indices(i)).frequency) &
                                    ", Leaf = " & boolean'image(nodes(temp_indices(i)).is_leaf) & ")";
                        end loop;
                        report "----------------------------------------";
                    end if;

                    sorted_indices <= temp_indices;
                    state <= merge_state;

                    when merge_state =>
                    if sorted_size > 1 then
                        -- 2 smallest frequency nodes
                        min1_index := sorted_indices(0);
                        min2_index := sorted_indices(1);
                        
                        -- Temp node to track freq
                        temp_nodes := nodes;
                        
                        -- Calc new merged node
                        temp_node.frequency := temp_nodes(min1_index).frequency + temp_nodes(min2_index).frequency;
                        temp_node.left_child := min1_index;
                        temp_node.right_child := min2_index;
                        temp_node.is_leaf := false;
                        temp_node.character := (others => '0');
                        
                        -- Update temp array 
                        temp_nodes(next_node_index) := temp_node;
                        
                        if SHOW_DEBUG then
                            report "Merging: Node " & integer'image(min1_index) & 
                                " (Freq=" & integer'image(temp_nodes(min1_index).frequency) & 
                                ") and Node " & integer'image(min2_index) & 
                                " (Freq=" & integer'image(temp_nodes(min2_index).frequency) & 
                                ") -> New Node " & integer'image(next_node_index) &
                                " (Total Freq=" & integer'image(temp_node.frequency) &
                                ", Left=" & integer'image(min1_index) & 
                                ", Right=" & integer'image(min2_index) & ")";
                        end if;
                        
                        -- Assign to actual array
                        nodes(next_node_index) <= temp_node;
                        
                        -- Update array
                        temp_indices := sorted_indices;
                        
                        -- Shift left
                        for i in 0 to sorted_size - 3 loop
                            temp_indices(i) := sorted_indices(i + 2);
                        end loop;
                        
                        -- Add new node
                        temp_indices(sorted_size - 2) := next_node_index;
                        
                        -- Sort from temp_nodes
                        for i in 0 to sorted_size - 3 loop
                            for j in 0 to sorted_size - i - 3 loop
                                if temp_nodes(temp_indices(j)).frequency > temp_nodes(temp_indices(j + 1)).frequency then
                                    temp_index := temp_indices(j);
                                    temp_indices(j) := temp_indices(j + 1);
                                    temp_indices(j + 1) := temp_index;
                                end if;
                            end loop;
                        end loop;
                
                        if SHOW_DEBUG then
                            report "After merge and sort:";
                            for i in 0 to sorted_size - 2 loop
                                report "Index " & integer'image(i) & ": Node " & 
                                    integer'image(temp_indices(i)) & 
                                    " (Freq = " & integer'image(temp_nodes(temp_indices(i)).frequency) & ")";
                            end loop;
                        end if;
                        
                        sorted_indices <= temp_indices;
                        sorted_size <= sorted_size - 1;
                        next_node_index <= next_node_index + 1;
                        
                    else
                        if SHOW_DEBUG then
                            report "Merging complete. Root index = " & integer'image(sorted_indices(0));
                        end if;
                        
                        root_index_sig <= sorted_indices(0);
                        merge_done <= '1';
                        state <= done_state;
                    end if;

                    when done_state =>
                    if not write_complete then
                        for i in 0 to next_node_index-1 loop
                            write_node_info(tree_file, i, nodes(i));
                        end loop;
                        write_complete <= true;
                        merge_done <= '1';
                    end if;
                
                when others =>
                    state <= done_state;
            end case;
        end if;
    end process;

end Behavioral;
