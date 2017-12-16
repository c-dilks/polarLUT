#!/bin/bash

touch pol_99_analysed_runs.root
rm pol_99_analysed_runs.root
hadd pol_99_analysed_runs.root pol_12_analysed_runs.root pol_13_analysed_runs.root

echo "RUN 12------------------------------------------------"
root -b -q ComputeOverallPol.C'("pol_12_analysed_runs.root")'
echo "RUN 13------------------------------------------------"
root -b -q ComputeOverallPol.C'("pol_13_analysed_runs.root")'
echo "RUN 12 + 13 ------------------------------------------"
root -b -q ComputeOverallPol.C'("pol_99_analysed_runs.root")'
