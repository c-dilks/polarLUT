#!/bin/bash
# generate times.list and fills.list, needed for polarLUT

# note: if you want runs 12 or 13, you will need to change the sqlport
# (usually it is just the run number + 3399; e.g., for run 12, port 3411)
# this script must be run on a machine which can access stardb, such as onl05

# run 15
sqlhost="dbbak.starp.bnl.gov"
sqlport=3414

mysql --host $sqlhost --port $sqlport RunLog -N -e \
 "SELECT runNumber,startRunTime,endRunTime FROM runDescriptor" | uniq > times.list

mysql --host $sqlhost --port $sqlport RunLog -N -e \
 "SELECT runNumber,blueFillNumber FROM beamInfo WHERE entryTag=0" | uniq > fills.list
