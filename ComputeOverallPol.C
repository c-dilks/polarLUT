// computes:
// - integrated luminosity
// - overall lumi-weighted average polarization +/- overall error, including systematics

void ComputeOverallPol(TString filename="pol_12.root") {
  TFile * infile = new TFile(filename.Data(),"READ");
  TTree * tr = (TTree*) infile->Get("poltr");


  Double_t b_pol_lw,y_pol_lw;
  Double_t b_pol_lw_E,y_pol_lw_E;
  Double_t lumi_fill;
  Int_t fill;

  tr->SetBranchAddress("b_pol_lw",&b_pol_lw);
  tr->SetBranchAddress("y_pol_lw",&y_pol_lw);
  tr->SetBranchAddress("b_pol_lw_E",&b_pol_lw_E);
  tr->SetBranchAddress("y_pol_lw_E",&y_pol_lw_E);
  tr->SetBranchAddress("lumi_fill",&lumi_fill);
  tr->SetBranchAddress("fill",&fill);


  // compute total integrated lumi, total number of fills, and sum of squares of sigma_lumi-weighted_pol * lumi_of_fill
  Int_t fill_tmp=0;
  Double_t INT_LUMI = 0; // total integrated luminosity
  Double_t SUM_blue = 0; // for sum of lumi_of_fill * lumi-weighted_pol
  Double_t SUM_yell = 0; // for sum of lumi_of_fill * lumi-weighted_pol
  Double_t SUM_OF_SQUARES_ERR_blue = 0; // for quadrature sum of sigma_lumi-weighted_pol * lumi_of_fill
  Double_t SUM_OF_SQUARES_ERR_yell = 0; // for quadrature sum of sigma_lumi-weighted_pol * lumi_of_fill
  Int_t NFILLS = 0;
  for(int x=0; x<tr->GetEntries(); x++) {
    tr->GetEntry(x);
    if(fill!=fill_tmp) {
      INT_LUMI += lumi_fill;
      NFILLS++;
      SUM_blue += b_pol_lw * lumi_fill;
      SUM_yell += y_pol_lw * lumi_fill;
      SUM_OF_SQUARES_ERR_blue += TMath::Power( b_pol_lw_E * lumi_fill, 2);
      SUM_OF_SQUARES_ERR_yell += TMath::Power( y_pol_lw_E * lumi_fill, 2);
      fill_tmp = fill;
    };
  };
  Double_t POL_blue = (1/INT_LUMI) * SUM_blue; // overall lumi-weighted average pol. 
  Double_t POL_yell = (1/INT_LUMI) * SUM_yell; // overall lumi-weighted average pol. 
  Double_t SIGMA_POL_blue = (1/INT_LUMI) * TMath::Sqrt(SUM_OF_SQUARES_ERR_blue); // statistical uncertainty on lumi-weighted overall pol.
  Double_t SIGMA_POL_yell = (1/INT_LUMI) * TMath::Sqrt(SUM_OF_SQUARES_ERR_yell); // statistical uncertainty on lumi-weighted overall pol.


  // numbers for systematics & correction factors
  Int_t year;
  sscanf(filename.Data(),"pol_%d.root",&year);
  Int_t NFILLS_AN_blue, NFILLS_AN_yell;
  Float_t SYS_SCALE;
  Float_t SYS_PROFILE;
  switch(year) {
    case 12:
      NFILLS_AN_blue = 49;
      NFILLS_AN_yell = 49;
      SYS_SCALE = 0.066;
      SYS_PROFILE = 0.031 / TMath::Sqrt(NFILLS);
      break;
    case 13:
      NFILLS_AN_blue = 138;
      NFILLS_AN_yell = 139;
      SYS_SCALE = 0.064;
      SYS_PROFILE = 0.031 / TMath::Sqrt(NFILLS);
      break;
  };


  // overcounting correction
  Double_t SIGMA_POL_CORR_blue = SIGMA_POL_blue * ( NFILLS < NFILLS_AN_blue ? (TMath::Sqrt(1-((Float_t)NFILLS)/((Float_t)NFILLS_AN_blue))) : 0.0 );
  Double_t SIGMA_POL_CORR_yell = SIGMA_POL_yell * ( NFILLS < NFILLS_AN_yell ? (TMath::Sqrt(1-((Float_t)NFILLS)/((Float_t)NFILLS_AN_yell))) : 0.0 );


  // quadrature sum with systematics
  Double_t SIGMA_POL_TOT_blue = TMath::Sqrt( TMath::Power(SIGMA_POL_CORR_blue, 2) + 
                                             TMath::Power(POL_blue * SYS_SCALE, 2) +
                                             TMath::Power(POL_blue * SYS_PROFILE, 2));
  Double_t SIGMA_POL_TOT_yell = TMath::Sqrt( TMath::Power(SIGMA_POL_CORR_yell, 2) + 
                                             TMath::Power(POL_yell * SYS_SCALE, 2) +
                                             TMath::Power(POL_yell * SYS_PROFILE, 2));

  // print out for latex
  printf("\n\n\n");
  printf("\\begin{aligned}\n");
  printf("& year = %d \\\\\n",year);
  printf("& L_{int} = %.3f \\\\\n",INT_LUMI);
  printf("& \\mathbb{P}_B = %.3f \\pm %.3f \\\\\n",POL_blue,SIGMA_POL_TOT_blue);
  printf("& \\mathbb{P}_Y = %.3f \\pm %.3f \\\\\n",POL_yell,SIGMA_POL_TOT_yell);
  printf("& \\sigma_{\\mathbb{P}_B,corr} = Re\\left(\\sqrt{1-%d/%d}\\right)\\cdot %.3f = %.3f \\\\\n",NFILLS,NFILLS_AN_blue,SIGMA_POL_blue,SIGMA_POL_CORR_blue);
  printf("& \\sigma_{\\mathbb{P}_Y,corr} = Re\\left(\\sqrt{1-%d/%d}\\right)\\cdot %.3f = %.3f \\\\\n",NFILLS,NFILLS_AN_yell,SIGMA_POL_yell,SIGMA_POL_CORR_yell);
  printf("& \\mathbb{P_B}\\cdot\\sigma_{scale}/P = %.3f \\cdot %.3f = %.3f \\\\\n",POL_blue,SYS_SCALE,POL_blue*SYS_SCALE);
  printf("& \\mathbb{P_Y}\\cdot\\sigma_{scale}/P = %.3f \\cdot %.3f = %.3f \\\\\n",POL_yell,SYS_SCALE,POL_yell*SYS_SCALE);
  printf("& \\mathbb{P_B}\\cdot\\sigma_{profile}/P = %.3f \\cdot %.3f = %.3f \\\\\n",POL_blue,SYS_PROFILE,POL_blue*SYS_PROFILE);
  printf("& \\mathbb{P_Y}\\cdot\\sigma_{profile}/P = %.3f \\cdot %.3f = %.3f \\\\\n",POL_yell,SYS_PROFILE,POL_yell*SYS_PROFILE);
  printf("\\end{aligned}\n");

};
