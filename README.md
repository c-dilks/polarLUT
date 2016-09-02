# polarLUT
generalized polarimetery LUT

## setup
build symlinks to list of good runs
- `for y in {12,13}; do ln -s /star/u/dilks/trgmon${y}/500/goodruns.dat goodruns_${y}.dat; done`

## running
just execute `UpdateLUT.pl [$year=12 or 13]`


this will produce `pol_$year.root` with the polarimetry tree
needed by `spinlong`
 - `pol_${year}.root` contains polarimetry tree and TCanvases
 - `pngs/` contains useful plots (see drupal post 7/25/16)


set `$debug=1` for extra debugging steps and branches
 - vimdiff to check if the table was re-formatted properly; the left-side
   file is the re-formatted table and differences between it and the
   original table are highlighted. Use the arrow keys to move around and
   check the differences. Type `ESC : q a ENTER` to quit vimdiff.

## overall polarization and error
execute `ComputeOverallPol.C`, this will print a bunch of latex lines, in which the final results are embedded
