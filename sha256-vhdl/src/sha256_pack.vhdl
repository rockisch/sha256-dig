library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha256_pack is

  type commands is record
    init_load: std_logic;
    sched_en: std_logic;
    comp_en: std_logic;
    out_en: std_logic;
  end record;

end package sha256_pack;