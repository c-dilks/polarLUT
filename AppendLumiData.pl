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
  else {
    print("unknown year, terminating\n");
    exit;
  }
}

# open lumi file
$lumifile = $lumidir."/lum_perrun_FMS${trigger}.txt";
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


# generate hash tables
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
  
  if(exists $lumi_of_fill{$fillnum} ) { $lumi_of_fill{$fillnum} += $lumival; }
  else { $lumi_of_fill{$fillnum} = $lumival; }
  $fill_of_run{$runnum} = $fillnum;
  $lumi_of_run{$runnum} = $lumival;
};
#print Dumper(\%fill_of_run);
#print Dumper(\%lumi_of_run);
#print Dumper(\%lumi_of_fill);


# compute lumi weighted averages of polarizations
  my $kRunnum = 2;   #pol_data enum
  my $kFillnum = 1;  #pol_data enum
  my $kBlue_pol = 4; #pol_data enum
  my $kYell_pol = 6; #pol_data enum
my $blue_pol;
my $yell_pol;
my $summand_blue;
my $summand_yell;
my %lw_blue_pol_of_fill; # lumi weighted polarization, keyed by fill number
my %lw_yell_pol_of_fill; # lumi weighted polarization, keyed by fill number
open(POLDATA,"polar_by_run.dat") or die("ERROR: polar_by_run.dat not found\n");
foreach $line (<POLDATA>) {
  chomp($line);
  my @pol_data = split " ", $line;
  $fillnum = $pol_data[$kFillnum];
  $runnum = $pol_data[$kRunnum];
  $blue_pol = $pol_data[$kBlue_pol];
  $yell_pol = $pol_data[$kYell_pol];

  $summand_blue = 0;
  $summand_yell = 0;

  if(exists $lumi_of_run{$runnum} and exists $lumi_of_fill{$fillnum}) {
    if($lumi_of_fill{$fillnum}>0) {
      $summand_blue = $lumi_of_run{$runnum} * $blue_pol / $lumi_of_fill{$fillnum};
      $summand_yell = $lumi_of_run{$runnum} * $yell_pol / $lumi_of_fill{$fillnum};
    }
  }

  if(exists $lw_blue_pol_of_fill{$fillnum}) { $lw_blue_pol_of_fill{$fillnum} += $summand_blue; }
  else { $lw_blue_pol_of_fill{$fillnum} = $summand_blue; }

  if(exists $lw_yell_pol_of_fill{$fillnum}) { $lw_yell_pol_of_fill{$fillnum} += $summand_yell; }
  else { $lw_yell_pol_of_fill{$fillnum} = $summand_yell; }
}
seek(POLDATA,0,0);


# write new data table, with luminosity values and luminosity-weighted polarizations appended;
# if there's no luminosity value, we write zeroes in for the luminosities and write the usual t-dependent
# polarizations in place of the luminosity-weighted polarization values
open(POLDATA_OUT,"> polar_by_run_with_lumi.dat");
my $lumi_run;
my $lumi_fill;
my $lw_blue_pol;
my $lw_yell_pol;
foreach $line (<POLDATA>) {
  chomp($line);
  my @pol_data = split " ", $line;
  $fillnum = $pol_data[$kFillnum];
  $runnum = $pol_data[$kRunnum];
  $blue_pol = $pol_data[$kBlue_pol];
  $yell_pol = $pol_data[$kYell_pol];

  if(exists $lumi_of_fill{$fillnum}) {
    $lumi_fill = $lumi_of_fill{$fillnum};
    $lw_blue_pol = $lw_blue_pol_of_fill{$fillnum};
    $lw_yell_pol = $lw_yell_pol_of_fill{$fillnum};
  } else {
    $lumi_fill = 0;
    $lw_blue_pol = $blue_pol;
    $lw_yell_pol = $yell_pol;
  }

  if(exists $lumi_of_run{$runnum}) { $lumi_run = $lumi_of_run{$runnum}; }
  else { $lumi_run = 0; }

  print(POLDATA_OUT "$line $lumi_run $lumi_fill $lw_blue_pol $lw_yell_pol\n");
};
close(POLDATA_OUT);
close(POLDATA);
