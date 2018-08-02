#!/usr/bin/perl -w
use Data::Dumper;
use Switch;


# get year number
if($#ARGV!=1) {
  print "must have arguments [year] [trigger]";
  exit;
}
my $year = $ARGV[0];
my $trigger = $ARGV[1];


my $lumidir;
switch($year) {
  case 12 {
    $lumidir = "/afs/rhic/star/doc_protected/docp1/common/common2012/trigger2012/lumipp500GeV";
  }
  case 13 {
    $lumidir = "/afs/rhic/star/doc_protected/docp1/common/common2013/trigger2013/lumipp500GeV";
  }
  case 15 {
    $lumidir = ""; # not used
    #`./FetchRun15lumi.sh ${trigger}`; # use this if you're on RCAS
  }
  else {
    print("unknown year, terminating\n");
    exit;
  }
}


# first, determine for which runs we have polarimetry measurements, so that we
# which runs' luminosities to add together to determine the per-fill lumi
open(POLDATA,"polar_by_run.dat") or die("ERROR: polar_by_run.dat not found\n");
my @runlist;
foreach $line (<POLDATA>) {
  chomp($line);
  my @arr = split " ", $line;
  push(@runlist,$arr[2]);
}
#print Dumper(\@runlist);


# open lumi file
if($year!=15) { $lumifile = $lumidir."/lum_perrun_FMS${trigger}.txt"; }
#else { $lumifile = "lumi_tmp.txt"; }
else { $lumifile = "lumi_${trigger}_15.txt"; }
open(LUMI,$lumifile) or die("ERROR: $lumifile does not exist");

# columns of luminosity tables:
#   0: Run
#   1: Seconds since Dec 31, 2011 00:00 America/New_York for Run Start
#   2: Seconds since Dec 31, 2011 00:00 America/New_York for Run end
#   3: Fill Number
#   4: Luminosity
#   5: Prescale
#   6: Live time for this trigger from the TCU
#   7: Name of base trigger for luminosity estimation
#   8: Live time for the base trigger from TCU
#   9: Figure of Merit as (P_B*P_B+P_Y*P_Y)/2 * Lum, where P is from the Jet measurements (0.5 for B and Y if no measurement)
#   10: Figure of Merit as P_B*P_B*P_Y*P_Y * Lum, same story for P
#   ... others for run 15..? doesn't matter...


# generate hash tables, which hash fill or run numbers into per-fill or per-run lumis
my %fill_of_run;
my %lumi_of_run;
my $lumi_of_fill;
my $runnum;
my $lumival;
my $fillnum;
foreach $line (<LUMI>) {
  chomp($line);
  my @lumi_data = split " ", $line;
  $runnum = $lumi_data[0];
  $fillnum = $lumi_data[3];
  $lumival = $lumi_data[4];

  # only hash runs which are in polar_by_run.dat 
  if(grep {$runnum eq $_} @runlist) {
    if(exists $lumi_of_fill{$fillnum} ) { 
      #print("DEBUG: add $lumival to $fillnum\n"); 
      $lumi_of_fill{$fillnum} += $lumival;
    }
    else { 
      #print("DEBUG: starting fill $fillnum at $lumival\n");
      $lumi_of_fill{$fillnum} = $lumival;
    }
    $fill_of_run{$runnum} = $fillnum;
    $lumi_of_run{$runnum} = $lumival;
  };
};
#print Dumper(\%fill_of_run);
#print Dumper(\%lumi_of_run);
#print Dumper(\%lumi_of_fill);


# compute lumi weighted averages of polarizations
  my $kRunnum = 2;   #pol_data enum
  my $kFillnum = 1;  #pol_data enum
  my $kBlue_pol = 4; #pol_data enum
  my $kYell_pol = 6; #pol_data enum
  my $kBlue_pol_ave = 5; #pol_data enum
  my $kYell_pol_ave = 7; #pol_data enum
  
  my $kBlue_p0 = 11; #pol_data enum
  my $kBlue_p1 = 12; #pol_data enum
  my $kYell_p0 = 13; #pol_data enum
  my $kYell_p1 = 14; #pol_data enum

  my $ktime = 8; # pol_data enum

  my $kBlue_pol_ave_E = 15; #pol_data enum
  my $kBlue_p0_E = 16; #pol_data enum
  my $kBlue_p1_E = 17; #pol_data enum
  my $kBlue_pol_E = 18; #pol_data enum

  my $kYell_pol_ave_E = 19; #pol_data enum
  my $kYell_p0_E = 20; #pol_data enum
  my $kYell_p1_E = 21; #pol_data enum
  my $kYell_pol_E = 22; #pol_data enum

my $blue_pol;
my $yell_pol;
my $blue_pol_E;
my $yell_pol_E;
my $blue_pol_ave;
my $yell_pol_ave;
my $blue_p0_E;
my $yell_p0_E;
my $blue_p1_E;
my $yell_p1_E;
my $blue_p0;
my $yell_p0;
my $blue_p1;
my $yell_p1;
my $blue_pol_ave_E;
my $yell_pol_ave_E;
my $time;

my $summand_blue;
my $summand_yell;
my $summand_prod;
my $summand_LT;
my $summand_LTsq;

my %lw_blue_pol_of_fill; # lumi weighted polarization, keyed by fill number
my %lw_yell_pol_of_fill; # lumi weighted polarization, keyed by fill number
my %lw_prod_pol_of_fill; # lumi weighted polarization product, keyed by fill number
my %LTsum_of_fill; # sum of run-lumi * run-time t (needed for lumi-weighted error), keyed by fill number
my %LTsqsum_of_fill; # sum of run-lumi * run-time t^2 (needed for lumi-weighted error), keyed by fill number

my %P0_blue_of_fill; # P0, keyed by fill
my %P0_yell_of_fill; # P0, keyed by fill
my %P1_blue_of_fill; # P1, keyed by fill
my %P1_yell_of_fill; # P1, keyed by fill

my %sigP0_blue_of_fill; # uncertainty on P0, keyed by fill
my %sigP0_yell_of_fill; # uncertainty on P0, keyed by fill
my %sigP1_blue_of_fill; # uncertainty on P1, keyed by fill
my %sigP1_yell_of_fill; # uncertainty on P1, keyed by fill


seek(POLDATA,0,0);
foreach $line (<POLDATA>) {
  chomp($line);
  my @pol_data = split " ", $line;

  $fillnum = $pol_data[$kFillnum];
  $runnum = $pol_data[$kRunnum];
  $blue_pol = $pol_data[$kBlue_pol];
  $yell_pol = $pol_data[$kYell_pol];
  $time = $pol_data[$ktime];

  $blue_p0_E = $pol_data[$kBlue_p0_E];
  $yell_p0_E = $pol_data[$kYell_p0_E];
  $blue_p1_E = $pol_data[$kBlue_p1_E];
  $yell_p1_E = $pol_data[$kYell_p1_E];

  $blue_p0 = $pol_data[$kBlue_p0];
  $yell_p0 = $pol_data[$kYell_p0];
  $blue_p1 = $pol_data[$kBlue_p1];
  $yell_p1 = $pol_data[$kYell_p1];

  $summand_blue = 0;
  $summand_yell = 0;
  $summand_prod = 0;
  $summand_LT = 0;
  $summand_LTsq = 0;


  if(exists $lumi_of_run{$runnum} and exists $lumi_of_fill{$fillnum}) {
    if($lumi_of_fill{$fillnum}>0) {
      $summand_blue = $lumi_of_run{$runnum} * $blue_pol / $lumi_of_fill{$fillnum}; # Lr*Pb/Lf
      $summand_yell = $lumi_of_run{$runnum} * $yell_pol / $lumi_of_fill{$fillnum}; # Lr*Py/LF
      $summand_prod = $lumi_of_run{$runnum} * $blue_pol * $yell_pol / $lumi_of_fill{$fillnum}; # Lr*Pb*Py/LF

      $summand_LT   = $lumi_of_run{$runnum} * $time;         # run's lumi * (run's midtime - fill starttime)
      $summand_LTsq = $lumi_of_run{$runnum} * $time * $time; # run's lumi * (run's midtime - fill starttime)^2
    }
  }


  if(exists $lw_blue_pol_of_fill{$fillnum}) { $lw_blue_pol_of_fill{$fillnum} += $summand_blue; }
  else { $lw_blue_pol_of_fill{$fillnum} = $summand_blue; }

  if(exists $lw_yell_pol_of_fill{$fillnum}) { $lw_yell_pol_of_fill{$fillnum} += $summand_yell; }
  else { $lw_yell_pol_of_fill{$fillnum} = $summand_yell; }

  if(exists $lw_prod_pol_of_fill{$fillnum}) { $lw_prod_pol_of_fill{$fillnum} += $summand_prod; }
  else { $lw_prod_pol_of_fill{$fillnum} = $summand_prod; }


  if(exists $LTsum_of_fill{$fillnum}) { $LTsum_of_fill{$fillnum} += $summand_LT; }
  else { $LTsum_of_fill{$fillnum} = $summand_LT; }

  if(exists $LTsqsum_of_fill{$fillnum}) { $LTsqsum_of_fill{$fillnum} += $summand_LTsq; }
  else { $LTsqsum_of_fill{$fillnum} = $summand_LTsq; }

  if(!(exists $P0_blue_of_fill{$fillnum})) { $P0_blue_of_fill{$fillnum} = $blue_p0; }
  if(!(exists $P0_yell_of_fill{$fillnum})) { $P0_yell_of_fill{$fillnum} = $yell_p0; }
  if(!(exists $P1_blue_of_fill{$fillnum})) { $P1_blue_of_fill{$fillnum} = $blue_p1; }
  if(!(exists $P1_yell_of_fill{$fillnum})) { $P1_yell_of_fill{$fillnum} = $yell_p1; }

  if(!(exists $sigP0_blue_of_fill{$fillnum})) { $sigP0_blue_of_fill{$fillnum} = $blue_p0_E; }
  if(!(exists $sigP0_yell_of_fill{$fillnum})) { $sigP0_yell_of_fill{$fillnum} = $yell_p0_E; }
  if(!(exists $sigP1_blue_of_fill{$fillnum})) { $sigP1_blue_of_fill{$fillnum} = $blue_p1_E; }
  if(!(exists $sigP1_yell_of_fill{$fillnum})) { $sigP1_yell_of_fill{$fillnum} = $yell_p1_E; }
}


# write new data table, with luminosity values and luminosity-weighted polarizations appended;
# if there's no luminosity value, we write zeroes in for the luminosities and write the usual t-dependent
# polarizations in place of the luminosity-weighted polarization values
open(POLDATA_OUT,"> polar_by_run_with_lumi.dat");
my $lumi_run;
my $lumi_fill;
my $lw_blue_pol;
my $lw_yell_pol;
my $lw_prod_pol;
my $lw_blue_pol_E;
my $lw_yell_pol_E;
my $lw_prod_pol_E;



# fill-by-fill scale systematic uncertainty (from pol. analysis note table 4)
my $SCALE_UNC_blue;
my $SCALE_UNC_yell;
my $SCALE_UNC_prod;
switch($year) {
  case 12 {
    $SCALE_UNC_blue = 0.000;
    $SCALE_UNC_yell = 0.031;
  }
  case 13 {
    $SCALE_UNC_blue = 0.028;
    $SCALE_UNC_yell = 0.014;
  }
  case 15 {
    $SCALE_UNC_blue = 0.0; # overridden below, since depends on pp vs. pAu vs. pAl
    $SCALE_UNC_yell = 0.0; # overridden below, since depends on pp vs. pAu vs. pAl
  }
}
$SCALE_UNC_prod = sqrt( ${SCALE_UNC_blue}**2 + ${SCALE_UNC_yell}**2 );


seek(POLDATA,0,0);
foreach $line (<POLDATA>) {
  chomp($line);
  my @pol_data = split " ", $line;
  $fillnum = $pol_data[$kFillnum];
  $runnum = $pol_data[$kRunnum];
  $blue_pol = $pol_data[$kBlue_pol];
  $yell_pol = $pol_data[$kYell_pol];
  $blue_pol_E = $pol_data[$kBlue_pol_E];
  $yell_pol_E = $pol_data[$kYell_pol_E];

  $blue_pol_ave = $pol_data[$kBlue_pol_ave];
  $yell_pol_ave = $pol_data[$kYell_pol_ave];
  $blue_pol_ave_E = $pol_data[$kBlue_pol_ave_E];
  $yell_pol_ave_E = $pol_data[$kYell_pol_ave_E];

  # run 15 systematic uncertainties:
  if($fillnum<18957) {
    $SCALE_UNC_blue = 0.0; #pp
    $SCALE_UNC_yell = 0.0; #pp
  } elsif($fillnum>=18957 && $fillnum<19170) {
    $SCALE_UNC_blue = 1.3; #pAu
    $SCALE_UNC_yell = 0.0; #pAu
  } elsif($fillnum>=19170) {
    $SCALE_UNC_blue = 0.0; #pAl
    $SCALE_UNC_yell = 0.0; #pAl
  }


  if(exists $lumi_of_fill{$fillnum}) {
    $lumi_fill = $lumi_of_fill{$fillnum};
    $lw_blue_pol = $lw_blue_pol_of_fill{$fillnum};
    $lw_yell_pol = $lw_yell_pol_of_fill{$fillnum};
    $lw_prod_pol = $lw_prod_pol_of_fill{$fillnum};
    $lw_blue_pol_E = sqrt( ( $sigP0_blue_of_fill{$fillnum} )**2 + 
                           ( ($sigP1_blue_of_fill{$fillnum}/$lumi_fill) * $LTsum_of_fill{$fillnum} )**2 +
                           ( $SCALE_UNC_blue * $lw_blue_pol )**2
                         );
    $lw_yell_pol_E = sqrt( ( $sigP0_yell_of_fill{$fillnum} )**2 + 
                           ( ($sigP1_yell_of_fill{$fillnum}/$lumi_fill) * $LTsum_of_fill{$fillnum} )**2 +
                           ( $SCALE_UNC_yell * $lw_yell_pol )**2
                         );
    $lw_prod_pol_E = sqrt( ( ($sigP0_blue_of_fill{$fillnum}/$lumi_fill) * 
                             ( $P0_yell_of_fill{$fillnum} * $lumi_fill + 
                               $P1_yell_of_fill{$fillnum} * $LTsum_of_fill{$fillnum}
                             ) 
                           )**2 +
                           ( ($sigP1_blue_of_fill{$fillnum}/$lumi_fill) *
                             ( $P0_yell_of_fill{$fillnum} * $LTsum_of_fill{$fillnum} + 
                               $P1_yell_of_fill{$fillnum} * $LTsqsum_of_fill{$fillnum}
                             ) 
                           ) **2 + 
                           ( ($sigP0_yell_of_fill{$fillnum}/$lumi_fill) * 
                             ( $P0_blue_of_fill{$fillnum} * $lumi_fill + 
                               $P1_blue_of_fill{$fillnum} * $LTsum_of_fill{$fillnum}
                             ) 
                           )**2 +
                           ( ($sigP1_yell_of_fill{$fillnum}/$lumi_fill) *
                             ( $P0_blue_of_fill{$fillnum} * $LTsum_of_fill{$fillnum} + 
                               $P1_blue_of_fill{$fillnum} * $LTsqsum_of_fill{$fillnum}
                             ) 
                           ) **2 + 
                           ( $SCALE_UNC_prod * $lw_prod_pol)**2 
                         );
  } else {
    $lumi_fill = 0;
    $lw_blue_pol = $blue_pol_ave;
    $lw_yell_pol = $yell_pol_ave;
    $lw_prod_pol = $blue_pol_ave * $yell_pol_ave;
    $lw_blue_pol_E = $blue_pol_ave_E;
    $lw_yell_pol_E = $yell_pol_ave_E;
    $lw_prod_pol_E = sqrt($blue_pol_ave_E**2 + $yell_pol_ave_E**2);
  }

  if(exists $lumi_of_run{$runnum}) { $lumi_run = $lumi_of_run{$runnum}; }
  else { $lumi_run = 0; }

  print(POLDATA_OUT "$line $lumi_run $lumi_fill $lw_blue_pol $lw_yell_pol $lw_blue_pol_E $lw_yell_pol_E $lw_prod_pol $lw_prod_pol_E\n");
};
close(POLDATA_OUT);
close(POLDATA);

#if($year==15) { `rm lumi_tmp.txt`; }
