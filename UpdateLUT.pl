#!/usr/bin/perl -w
use Data::Dumper;
use Switch;

# if =1, use alternate run list (search for this variable below); if false, just uses goodruns_${year}.dat's run list
my $USE_ALTERNATE_RUNLIST=0;

# if =1; turns on extra debugging stuff 
my $debug=0;

# if =1, use only runs in goodruns_${year}.dat
# otherwise if =0, use all runs found in DB
my $filter_goodruns=1;

# default trigger to use for lumi
my $def_trigger = "JP2";

# get year number
my $year;
my $trigger;
if($#ARGV==0 or $#ARGV==1) {
  $year = $ARGV[0];
  if($#ARGV==1) { $trigger = $ARGV[1]; }
  else { $trigger = $def_trigger; }
} else {
  print "specify year (12,13,15) as argument (and also optionally an FMS trigger for lumi calculation (default=${def_trigger}))\n";
  exit;
} 
print "year=$year trigger=$trigger\n\n";


# set SQL server coordinates
my $sqlhost;
my $sqlport;
my $sqlcmd;
my $url;

switch($year) {
  case 12 {
    $sqlhost="dbbak.starp.bnl.gov";
    $sqlport=3411;
    $sqlcmd="mysql --host ${sqlhost} --port ${sqlport} RunLog -N -e";
    $url="https://wiki.bnl.gov/rhicspin/Run_12_polarization";
  }
  case 13 {
    $sqlhost="dbbak.starp.bnl.gov";
    $sqlport=3412;
    $sqlcmd="mysql --host ${sqlhost} --port ${sqlport} RunLog -N -e";
    $url="https://wiki.bnl.gov/rhicspin/Run_13_polarization";
  }
  case 15 {
    $sqlhost="dbbak.starp.bnl.gov";
    $sqlport=3414;
    $sqlcmd="mysql --host ${sqlhost} --port ${sqlport} RunLog -N -e";
    $url="https://wiki.bnl.gov/rhicspin/Run_15_polarization";
  }
  else {
    print("unknown year, terminating\n");
    exit;
  }
}

my $storage_dir="data_${year}";
system("mkdir -p $storage_dir");

my $goodruns_file;
if($USE_ALTERNATE_RUNLIST==1) {
  $goodruns_file="runlist_pi0_${year}.dat";
} else {
  $goodruns_file="goodruns_${year}.dat";
}
print("RUNLIST = $goodruns_file \n\n");


# execute SQL queries and produce data tables
system("${sqlcmd} \"SELECT runNumber,startRunTime,endRunTime FROM runDescriptor\" | uniq > times.list");
system("${sqlcmd} \"SELECT runNumber,blueFillNumber FROM beamInfo\" | uniq > fills.list");

# open data tables
open(TIMES,"times.list") or die("ERROR: times.list not found");
open(FILLS,"fills.list") or die("ERROR: fills.list not found");


# read in list of good runs
my @goodruns;
open(GOOD,$goodruns_file) or die("ERROR: ${goodruns_file} not found");
foreach $line (<GOOD>) {
  chomp($line);
  my ($goodrun, $trash) = split " ",$line, 2;
  push(@goodruns,$goodrun);
}
#print Dumper(\@goodruns);


# obtain polarimetry data table
system("curl ${url}  > polarimetry.html");
system("grep -A5000 \"<pre>\" polarimetry.html | grep -B5000 \"</pre>\" | grep 1 | sed 's/<[^>]*>//g' > polarimetry.dat.tmp");
open(POL_TMP,"polarimetry.dat.tmp") or die("ERROR: polarimetry.dat.tmp not found");
open(POL,"> polarimetry.dat");

# some cells are empty in the data table; this block puts zeroes there and then opens
# the patched file together with the original data table in vimdiff for comparison; make
# sure it looks ok before proceeding!
my @char_idxes;
switch($year) {
  case 12 { @char_idxes = (39,48,56,65,73,82,90,99,107,116,125,133); }
  case 13 { @char_idxes = (50,59,67,76,84,93,101,110,118,127,135,144); }
  # case 15 is not needed
}
foreach $line (<POL_TMP>) {
  chomp($line);
  my ($fill, $trash) = split " ",$line, 2;
  
  if($year==12 || $year==13) {
    foreach my $char_idx (@char_idxes) {
      my $char = substr($line, $char_idx, 1);
      if("$char" eq " ") {
        substr($line,$char_idx-1,3) = "0.0";
      }
    }
  } elsif($year==15) {
    # put zero polarization in for yellow beam during pA part of run15
    if($fill >= 19000) {
      $line = "$line 0.0 0.0 0.0 0.0";
    }
    if($fill==19003) { next; }
  }
  print(POL "$line\n");
}
if($debug) {
  print("\n\nopening vimdiff to check to see if I filled zeroes in properly...\n");
  print("+/- symbols and nan's filtered out later\n");
  sleep 3;
  system("vimdiff polarimetry.dat{,.tmp}");
}
close(POL);


# build fill number hash table
my %fill_of_runnum; # runnumber --> fill number
foreach $line (<FILLS>) {
  my ($runnum, $fillnum) = split " ", $line;
  $fillnum =~ s/\..*$//;
  $fill_of_runnum{$runnum} = $fillnum;
}

# build run times hash table
# IMPORTANT NOTE: if the endtime is put in as zero, we
# just set the midtime of run equal to the start time;
# if the starttime is zero, we set the midtime to zero and
# have a cut on midtime>0 for valid polarization
my %start_of_run; # run number --> start time
my %end_of_run; # run number --> end time
my %mid_of_run; # run number --> mid time
foreach $line (<TIMES>) {
  my ($runnum, $starttime, $endtime) = split " ", $line;
  my $midtime;
  if($endtime>0) {
    $midtime = ($starttime+$endtime)/2;
  } else {
    $midtime = $starttime;
  }
  $start_of_run{$runnum} = $starttime;
  $end_of_run{$runnum} = $endtime;
  $mid_of_run{$runnum} = $midtime;
}


# build polarimetry data hashed by fill number
# this is a hash of fill number to polarimetry data arrays
#  sample of accessing polarimetry data for a particular fill:
#  print("BlueAvg for fill $fill is $pol_of_fill{$fill}[$kBlueAvg]\n");
my %pol_of_fill; # fill number -> polarimetry data vector
my $pol_data_length;
  my $kFill;
  my $kBeamE;
  my $kStartT;
  my $kEndT;
  my $kBlueAvg;
  my $kBlueAvgErr;
  my $kBlueP0;
  my $kBlueP0Err;
  my $kBlueP1;
  my $kBlueP1Err;
  my $kYellAvg;
  my $kYellAvgErr;
  my $kYellP0;
  my $kYellP0Err;
  my $kYellP1;
  my $kYellP1Err;
my $ii = 0;
switch($year) {
  case 12 {
    $kFill = $ii++;
    $kBeamE = $ii++;
    $kStartT = $ii++;
    $kEndT = -1;

    $kBlueAvg = $ii++;
    $kBlueAvgErr = $ii++;
    $kBlueP0 = $ii++;
    $kBlueP0Err = $ii++;
    $kBlueP1 = $ii++;
    $kBlueP1Err = $ii++;

    $kYellAvg = $ii++;
    $kYellAvgErr = $ii++;
    $kYellP0 = $ii++;
    $kYellP0Err = $ii++;
    $kYellP1 = $ii++;
    $kYellP1Err = $ii++;
  }
  case 13 {
    $kFill = $ii++;
    $kBeamE = $ii++;
    $kStartT = $ii++;
    $kEndT = $ii++;

    $kBlueAvg = $ii++;
    $kBlueAvgErr = $ii++;
    $kBlueP0 = $ii++;
    $kBlueP0Err = $ii++;
    $kBlueP1 = $ii++;
    $kBlueP1Err = $ii++;

    $kYellAvg = $ii++;
    $kYellAvgErr = $ii++;
    $kYellP0 = $ii++;
    $kYellP0Err = $ii++;
    $kYellP1 = $ii++;
    $kYellP1Err = $ii++;
  }
  case 15 {
    $kFill = $ii++;
    $kBeamE = $ii++;
    $kStartT = $ii++;
    $kEndT = $ii++;

    $kBlueAvg = -1;
    $kBlueAvgErr = -1;
    $kBlueP0 = $ii++;
    $kBlueP0Err = $ii++;
    $kBlueP1 = $ii++;
    $kBlueP1Err = $ii++;

    $kYellAvg = -1;
    $kYellAvgErr = -1;
    $kYellP0 = $ii++;
    $kYellP0Err = $ii++;
    $kYellP1 = $ii++;
    $kYellP1Err = $ii++;
  }
}
$pol_data_length = $ii;



# build
open(POLDATA,"polarimetry.dat");
print "building polarimetry hash table...\n";
foreach $line (<POLDATA>) {
  my ($fill, $trash) = split " ",$line, 2;
  $line =~ s/\+-//g;
  $line =~ s/\+\/-//g;
  $line =~ s/nan//g;
  my @pol_data = split " ", $line;

  #print "$line\n";
  #print Dumper(\@pol_data);

  $pol_of_fill{$fill} = \@pol_data;
  if ( scalar @pol_data != $pol_data_length ) {
    print "ERROR: fill $fill not formatted properly in polarimetry.dat\n";
  }
}
if($debug) { print Dumper(\%pol_of_fill); }


# determine run-by-run polarization
my $t;
my $st;
my $mt;
my $et;
my $BlueP0;
my $BlueP1;
my $BluePol;
my $BlueAvg;
my $BlueDiff;
my $BlueP0Err;
my $BlueP1Err;
my $BluePolErr;
my $BlueAvgErr;
my $YellP0;
my $YellP1;
my $YellPol;
my $YellAvg;
my $YellDiff;
my $YellP0Err;
my $YellP1Err;
my $YellPolErr;
my $YellAvgErr;
my $run_idx=0;
open(OUT,"> polar_by_run.dat");
seek(FILLS,0,0);
my $exe;
foreach $line (<FILLS>) {
  my ($runnum, $fillnum) = split " ", $line;
  $fillnum = int($fillnum);

  # goodruns filter
  if($filter_goodruns==1) {
    $exe = (grep {$runnum eq $_} @goodruns) ? 1:0;
  } elsif($filter_goodruns==0) {
    $exe = 1;
  } else {
    print "ERROR: \$filter_goodruns must be 0 or 1\n";
    exit;
  }

  if($exe==1) {
    if(exists $pol_of_fill{$fillnum}) {
      @pol_data = @{$pol_of_fill{$fillnum}};

      # time elapsed from beginning of fill (in hours)
      $st = $start_of_run{$runnum};
      $mt = $mid_of_run{$runnum};
      $et = $end_of_run{$runnum};
      $t = ($mt - $pol_data[$kStartT]) / 3600.0;
      
      # blue polarization
      $BlueP0 = $pol_data[$kBlueP0];
      $BlueP1 = $pol_data[$kBlueP1];
      $BluePol = $BlueP0 + ($t * $BlueP1);
      if($year!=15) { $BlueAvg = $pol_data[$kBlueAvg]; }
      else { $BlueAvg = 0; }
      $BlueDiff = $BluePol - $BlueAvg;
      #if(abs($BlueP0)<1 or abs($BlueP1)<0.001) { $BluePol = 0.0; }
      if(abs($BlueP0)<1) { $BluePol = $BlueAvg; }

      # blue polarization error
      if($year!=15) { $BlueAvgErr = $pol_data[$kBlueAvgErr]; }
      else { $BlueAvgErr = 0; }
      $BlueP0Err = $pol_data[$kBlueP0Err]; 
      $BlueP1Err = $pol_data[$kBlueP1Err]; 
      $BluePolErr = sqrt($BlueP0Err**2 + (($t**2) * ($BlueP1Err**2))); # (not used any more; prefer errors on P0 & P1)

      

      # yellow polarization
      $YellP0 = $pol_data[$kYellP0];
      $YellP1 = $pol_data[$kYellP1];
      $YellPol = $YellP0 + ($t * $YellP1);
      if($year!=15) { $YellAvg = $pol_data[$kYellAvg]; }
      else { $YellAvg = 0; }
      $YellDiff = $YellPol - $YellAvg;
      # if(abs($YellP0)<1 or abs($YellP1)<0.001) { $YellPol = 0.0; }
      if(abs($YellP0)<1) { $YellPol = $YellAvg; }

      # yellow polarization error
      if($year!=15) { $YellAvgErr = $pol_data[$kYellAvgErr]; }
      else { $YellAvgErr = 0; }
      $YellP0Err = $pol_data[$kYellP0Err]; 
      $YellP1Err = $pol_data[$kYellP1Err]; 
      $YellPolErr = sqrt($YellP0Err**2 + (($t**2) * ($YellP1Err**2))); # (not used any more; prefer errors on P0 & P1)


      # switch units from "percent" to "unitless"
      $BluePol /= 100.0;
      $BlueAvg /= 100.0;
      $BlueP0 /= 100.0;
      $BlueP1 /= 100.0;
      $BluePolErr /= 100.0;
      $BlueAvgErr /= 100.0;
      $BlueP0Err /= 100.0;
      $BlueP1Err /= 100.0;

      $YellPol /= 100.0;
      $YellAvg /= 100.0;
      $YellP0 /= 100.0;
      $YellP1 /= 100.0;
      $YellPolErr /= 100.0;
      $YellAvgErr /= 100.0;
      $YellP0Err /= 100.0;
      $YellP1Err /= 100.0;


      # print output
      print(OUT "$run_idx $fillnum $runnum $st $BluePol $BlueAvg $YellPol $YellAvg"); # [0-7]
      print(OUT " $t $mt $et $BlueP0 $BlueP1 $YellP0 $YellP1"); # [8-14]
      print(OUT " $BlueAvgErr $BlueP0Err $BlueP1Err $BluePolErr"); # [15-18]
      print(OUT " $YellAvgErr $YellP0Err $YellP1Err $YellPolErr"); # [19-22]
      print(OUT "\n");

      $run_idx++;
    }
  }
}
close(OUT);

# compute luminosity-weighted polarizations
system("AppendLumiData.pl ${year} ${trigger}");

my $rootfile = "pol_${year}.root";
system("root -b -q -l BuildTree.C'(\"${rootfile}\",\"polar_by_run_with_lumi.dat\")'");

system("mv fills.list times.list ${storage_dir}/");
system("mv polarimetry.dat.tmp polarimetry.dat polar_by_run.dat polar_by_run_with_lumi.dat ${storage_dir}/");
system("rm polarimetry.html");

print("${rootfile} created; data files stored in ${storage_dir}\n");
