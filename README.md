# polarLUT
generalized polarimetery LUT

just execute `UpdateLUT.pl [$year=12 or 13]`

this will produce `pol_$year.root` with the polarimetry tree
needed by `spinlong`

set `$debug=1` for extra debugging steps and branches
 - vimdiff to check if the table was re-formatted properly; the left-side
   file is the re-formatted table and differences between it and the
   original table are highlighted. Use the arrow keys to move around and
   check the differences. Type `ESC : q a ENTER` to quit vimdiff.
