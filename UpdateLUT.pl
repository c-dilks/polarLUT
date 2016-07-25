#!/usr/bin/perl -w
use Data::Dumper;
use Switch;

my $debug=0;

# get year number
if($#ARGV!=0) {
  print "specify year (12,13,etc.) as argument\n";
  exit;
}
my $year = $ARGV[0];

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
  else {
    print("unknown year, terminating\n");
    exit;
  }
}

my $storage_dir="data_${year}";
system("mkdir -p $storage_dir");


# execute SQL queries and produce data tables
system("${sqlcmd} \"SELECT runNumber,startRunTime,endRunTime FROM runDescriptor\" | uniq > times.list");
system("${sqlcmd} \"SELECT runNumber,blueFillNumber FROM beamInfo\" | uniq > fills.list");

# open data tables
open(TIMES,"times.list") or die("times.list not found");
open(FILLS,"fills.list") or die("fills.list not found");




# obtain polarimetry data table
system("curl ${url}  > polarimetry.html");
system("grep -A5000 \"<pre>\" polarimetry.html | grep -B5000 \"</pre>\" | grep 1 | sed 's/<[^>]*>//g' > polarimetry.dat.tmp");
open(POL_TMP,"polarimetry.dat.tmp") or die("polarimetry.dat.tmp not found");
open(POL,"> polarimetry.dat");

# some cells are empty in the data table; this block puts zeroes there and then opens
# the patched file together with the original data table in vimdiff for comparison; make
# sure it looks ok before proceeding!
my @char_idxes;
switch($year) {
  case 12 { @char_idxes = (39,48,56,65,73,82,90,99,107,116,125,133); }
  case 13 { @char_idxes = (50,59,67,76,84,93,101,110,118,127,135,144); }
}
foreach $line (<POL_TMP>) {
  chomp($line);
  my ($fill, $trash) = split " ",$line, 2;
  foreach my $char_idx (@char_idxes) {
    my $char = substr($line, $char_idx, 1);
    if("$char" eq " ") {
      substr($line,$char_idx-1,3) = "0.0";
    }
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
switch($year) {
  case 12 {$pol_data_length=15;}
  case 13 {$pol_data_length=16;}
}
# polarimetry data vector indices:
  my $ii=0;

  my $kFill=$ii++; # = 0
  my $kBeamE=$ii++;
  my $kStartT=$ii++;
  my $kEndT=-1;
  if($year==13) { $kEndT=$ii++;} # extra (and unused) column in run13
  my $kBlueAvg=$ii++;
  my $kBlueAvgErr=$ii++;
  my $kBlueP0=$ii++;
  my $kBlueP0Err=$ii++;
  my $kBlueP1=$ii++;
  my $kBlueP1Err=$ii++;
  my $kYellAvg=$ii++;
  my $kYellAvgErr=$ii++;
  my $kYellP0=$ii++;
  my $kYellP0Err=$ii++;
  my $kYellP1=$ii++;
  my $kYellP1Err=$ii++; # = 14 for run12, 15 for run13

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
#print Dumper(\%pol_of_fill);


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
my $YellP0;
my $YellP1;
my $YellPol;
my $YellAvg;
my $YellDiff;
my $run_idx=0;
open(OUT,"> polar_by_run.dat");
seek(FILLS,0,0);
foreach $line (<FILLS>) {
  my ($runnum, $fillnum) = split " ", $line;
  $fillnum = int($fillnum);
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
    $BlueAvg = $pol_data[$kBlueAvg];
    $BlueDiff = $BluePol - $BlueAvg;

    # yellow polarization
    $YellP0 = $pol_data[$kYellP0];
    $YellP1 = $pol_data[$kYellP1];
    $YellPol = $YellP0 + ($t * $YellP1);
    $YellAvg = $pol_data[$kYellAvg];
    $YellDiff = $YellPol - $YellAvg;


    print(OUT "$run_idx $fillnum $runnum $st $BluePol $BlueAvg $YellPol $YellAvg");
    if($debug or 1) {
      print(OUT " $t $mt $et $BlueP0 $BlueP1 $YellP0 $YellP1");
    }
    print(OUT "\n");

    $run_idx++;
  }
}
close(OUT);

my $rootfile = "pol_${year}.root";
system("root -b -q -l BuildTree.C'(1,\"${rootfile}\")'");

system("mv fills.list times.list ${storage_dir}/");
system("mv polarimetry.dat.tmp polarimetry.dat polar_by_run.dat ${storage_dir}/");
system("rm polarimetry.html");

print("${rootfile} created; data files stored in ${storage_dir}\n");
