library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity string_frequency is
end entity;

architecture behavioral of string_frequency is
    constant MAX_LENGTH: integer := 256;

    type char_array is array (0 to MAX_LENGTH-1) of character;
    signal input_string: char_array := (others => ' ');
    signal input_length: integer := 0;

    type freq_array is array (character range 'a' to 'z') of integer;
    signal char_freq: freq_array := (others => 0);

    type sorted_array is array (0 to 25) of character;
    signal sorted_chars: sorted_array := ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 
                                          'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p',
                                          'q', 'r', 's', 't', 'u', 'v', 'w', 'x',
                                          'y', 'z');
begin
    read_file: process
        file input_file: text open read_mode is "input.txt";
        variable line: line;
        variable idx: integer := 0;
        variable char: character;
    begin
        readline(input_file, line);
        idx := 0;
        for i in 1 to line'length loop
            read(line, char);
            input_string(idx) <= char;
            idx := idx + 1;
        end loop;
        input_length <= idx;
        wait;
    end process;

    count_frequency: process
        variable local_freq: freq_array := (others => 0);
    begin
        for i in 0 to input_length-1 loop
            if input_string(i) >= 'a' and input_string(i) <= 'z' then
                local_freq(input_string(i)) := local_freq(input_string(i)) + 1;
            end if;
        end loop;
        char_freq <= local_freq;
        wait;
    end process;

    sort_frequency: process
        variable temp_char: character;
        variable temp_freq: integer;
        variable local_sorted: sorted_array := sorted_chars;
        variable local_freq: freq_array := (others => 0);
    begin
        for c in 'a' to 'z' loop
            local_freq(c) := char_freq(c);
        end loop;

        for i in local_sorted'range loop
            for j in 0 to 25-i-1 loop
                if local_freq(local_sorted(j)) < local_freq(local_sorted(j+1)) then
                    temp_char := local_sorted(j);
                    local_sorted(j) := local_sorted(j+1);
                    local_sorted(j+1) := temp_char;

                    temp_freq := local_freq(local_sorted(j));
                    local_freq(local_sorted(j)) := local_freq(local_sorted(j+1));
                    local_freq(local_sorted(j+1)) := temp_freq;
                end if;
            end loop;
        end loop;
        sorted_chars <= local_sorted;
        wait;
    end process;

end architecture;
