# polarLUT
generalized polarimetery LUT; to be executed on RCAS


## setup
build symlinks to list of good runs (if they aren't already there)
- using `trgmon` run QA output (execute on `rcas`):
  `for y in {12,13}; do ln -s /star/u/dilks/trgmon${y}/500/goodruns.dat goodruns_${y}.dat; done`
- or use final runlists from `A_LL` analysis; see `$USE_ALTERNATE_RUNLIST` in `UpdateLUT.pl`
- these files need to be stored 


## download latest polarimetry tables
this needs to be done manually from a non-rcas computer, since `curl` no longer works from rcas
- run 12: `curl https://wiki.bnl.gov/rhicspin/Run_12_polarization > polarimetry_12.html`
- run 13: `curl https://wiki.bnl.gov/rhicspin/Run_13_polarization > polarimetry_13.html`
- run 15: `curl https://wiki.bnl.gov/rhicspin/Run_15_polarization > polarimetry_15.html`


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


