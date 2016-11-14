#!/bin/bash

trig=$1

topdir="/afs/rhic/star/doc_protected/docp1/common/common2015/trigger2015"

> lumi_tmp.txt
cat ${topdir}/lumipp200GeV/lum_perrun_FMS-${trig}.txt >> lumi_tmp.txt
cat ${topdir}/lumipp200GeV/lum_perrun_FMS-${trig}-trans.txt >> lumi_tmp.txt
cat ${topdir}/lumipp200GeV/lum_perrun_FMS-${trig}-long.txt >> lumi_tmp.txt
cat ${topdir}/lumipAu200GeV/lum_perrun_FMS-${trig}.txt >> lumi_tmp.txt
cat ${topdir}/lumipAl200GeV/lum_perrun_FMS-${trig}.txt >> lumi_tmp.txt

cat lumi_tmp.txt | sort | uniq > lumi_tmp2.txt
mv lumi_tmp{2,}.txt
