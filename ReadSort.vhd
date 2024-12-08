library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ReadSort is
    Port (
        clk          : in  STD_LOGIC;
        reset        : in  STD_LOGIC;
        data_ready   : out STD_LOGIC;
        sorted_char  : out STD_LOGIC_VECTOR(7 downto 0);
        sorted_freq  : out INTEGER;
        done         : out STD_LOGIC
    );
end ReadSort;

architecture Behavioral of ReadSort is
    constant MAX_CHARS   : integer := 256;
    constant ASCII_RANGE : integer := 128;

    type char_array is array (0 to MAX_CHARS - 1) of character;
    type freq_array is array (0 to MAX_CHARS - 1) of integer;

    signal sorted_chars    : char_array := (others => ' ');
    signal sorted_freqs    : freq_array := (others => 0);
    signal data_index      : integer := 0;
    signal total_chars     : integer := 0;

    type state_type is (read_file, count_freq, sort_data, output_data, write_file, done_state);
    signal state : state_type := read_file;

    file input_file : text open read_mode is "Input";
    file output_file : text open write_mode is "Output";

    function char_to_slv(c : character) return STD_LOGIC_VECTOR is
    begin
        return std_logic_vector(to_unsigned(character'pos(c), 8));
    end function;

begin
    process(clk, reset)
        variable input_line     : line;
        variable temp_char      : character;
        variable unsorted_chars : char_array := (others => ' ');
        variable frequencies    : freq_array := (others => 0);
        variable char_count     : integer := 0;
        variable i, j, k        : integer;
        variable temp_freq      : integer;
        variable temp_char_var  : character;
        variable output_line    : line;
    begin
        if reset = '1' then
            state       <= read_file;
            data_index  <= 0;
            data_ready  <= '0';
            total_chars <= 0;
            done        <= '0';
        elsif rising_edge(clk) then
            case state is
                when read_file =>
                    if not endfile(input_file) then
                        readline(input_file, input_line);
                        for idx in input_line'range loop
                            if char_count < MAX_CHARS then
                                temp_char := input_line(idx);
                                unsorted_chars(char_count) := temp_char;
                                char_count := char_count + 1;
                            end if;
                        end loop;
                    else
                        total_chars <= char_count;
                        state <= count_freq;
                    end if;

                when count_freq =>
                    for i in 0 to total_chars - 1 loop
                        frequencies(character'pos(unsorted_chars(i))) := 
                            frequencies(character'pos(unsorted_chars(i))) + 1;
                    end loop;
                    state <= sort_data;

                when sort_data =>
                    j := 0;
                    -- collect non-zero frequency characters
                    for i in 0 to ASCII_RANGE - 1 loop
                        if frequencies(i) > 0 then
                            sorted_chars(j) <= character'val(i);
                            sorted_freqs(j) <= frequencies(i);
                            j := j + 1;
                        end if;
                    end loop;

                    -- bubble sort
                    for i in 0 to j - 2 loop
                        for k in 0 to j - i - 2 loop
                            if sorted_freqs(k) < sorted_freqs(k + 1) then
                                temp_freq := sorted_freqs(k);
                                sorted_freqs(k) <= sorted_freqs(k + 1);
                                sorted_freqs(k + 1) <= temp_freq;
                                temp_char_var := sorted_chars(k);
                                sorted_chars(k) <= sorted_chars(k + 1);
                                sorted_chars(k + 1) <= temp_char_var;
                            end if;
                        end loop;
                    end loop;
                    total_chars <= j;
                    data_index <= 0;
                    state <= output_data;

                when output_data =>
                    if data_index < total_chars then
                        sorted_char <= char_to_slv(sorted_chars(data_index));
                        sorted_freq <= sorted_freqs(data_index);
                        data_ready <= '1';
                        data_index <= data_index + 1;
                    else
                        data_ready <= '0';
                        state <= write_file;
                    end if;

                when write_file =>
                    for i in 0 to total_chars - 1 loop
                        write(output_line, sorted_chars(i));
                        write(output_line, string'(" "));
                        write(output_line, sorted_freqs(i));
                        writeline(output_file, output_line);
                    end loop;
                    state <= done_state;

                when done_state =>
                    data_ready <= '0';
                    done <= '1';

                when others =>
                    state <= done_state;
            end case;
        end if;
    end process;
end Behavioral;

