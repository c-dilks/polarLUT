// computes:
// - integrated luminosity
// - overall lumi-weighted average polarization +/- overall error, including systematics

void ComputeOverallPol(TString filename="pol_12_analysed_runs.root") {
  TFile * infile = new TFile(filename.Data(),"READ");
  TTree * tr = (TTree*) infile->Get("poltr");


  Double_t b_pol_lw,y_pol_lw,prod_pol_lw;
  Double_t b_pol_lw_E,y_pol_lw_E,prod_pol_lw_E;
  Double_t lumi_fill;
  Int_t fill;

  tr->SetBranchAddress("b_pol_lw",&b_pol_lw);
  tr->SetBranchAddress("y_pol_lw",&y_pol_lw);
  tr->SetBranchAddress("prod_pol_lw",&prod_pol_lw);
  tr->SetBranchAddress("b_pol_lw_E",&b_pol_lw_E);
  tr->SetBranchAddress("y_pol_lw_E",&y_pol_lw_E);
  tr->SetBranchAddress("prod_pol_lw_E",&prod_pol_lw_E);
  tr->SetBranchAddress("lumi_fill",&lumi_fill);
  tr->SetBranchAddress("fill",&fill);


  // compute total integrated lumi, total number of fills, and sum of squares of sigma_lumi-weighted_pol * lumi_of_fill
  Int_t fill_tmp=0;
  Double_t INT_LUMI = 0; // total integrated luminosity
  Double_t SUM_blue = 0; // for sum of lumi_of_fill * lumi-weighted_pol
  Double_t SUM_yell = 0; // for sum of lumi_of_fill * lumi-weighted_pol
  Double_t SUM_prod = 0; // for sum of lumi_of_fill * lumi-weighted_pol
  Double_t SUM_OF_SQUARES_ERR_blue = 0; // for quadrature sum of sigma_lumi-weighted_pol * lumi_of_fill
  Double_t SUM_OF_SQUARES_ERR_yell = 0; // for quadrature sum of sigma_lumi-weighted_pol * lumi_of_fill
  Double_t SUM_OF_SQUARES_ERR_prod = 0; // for quadrature sum of sigma_lumi-weighted_pol * lumi_of_fill
  Int_t NFILLS = 0;
  for(int x=0; x<tr->GetEntries(); x++) {
    tr->GetEntry(x);
    if(fill!=fill_tmp) {
      INT_LUMI += lumi_fill;
      NFILLS++;
      SUM_blue += b_pol_lw * lumi_fill;
      SUM_yell += y_pol_lw * lumi_fill;
      SUM_prod += prod_pol_lw * lumi_fill;
      //printf("b_pol_lw_E=%.2f lumi_fill=%f\n",b_pol_lw_E,lumi_fill);
      SUM_OF_SQUARES_ERR_blue += TMath::Power( b_pol_lw_E * lumi_fill, 2);
      SUM_OF_SQUARES_ERR_yell += TMath::Power( y_pol_lw_E * lumi_fill, 2);
      SUM_OF_SQUARES_ERR_prod += TMath::Power( prod_pol_lw_E * lumi_fill, 2);
      fill_tmp = fill;
    };
  };
  Double_t POL_blue = (1/INT_LUMI) * SUM_blue; // overall lumi-weighted average pol. 
  Double_t POL_yell = (1/INT_LUMI) * SUM_yell; // overall lumi-weighted average pol. 
  Double_t POL_prod = (1/INT_LUMI) * SUM_prod; // overall lumi-weighted average pol. 
  Double_t SIGMA_POL_blue = (1/INT_LUMI) * TMath::Sqrt(SUM_OF_SQUARES_ERR_blue); // statistical uncertainty on lumi-weighted overall pol.
  Double_t SIGMA_POL_yell = (1/INT_LUMI) * TMath::Sqrt(SUM_OF_SQUARES_ERR_yell); // statistical uncertainty on lumi-weighted overall pol.
  Double_t SIGMA_POL_prod = (1/INT_LUMI) * TMath::Sqrt(SUM_OF_SQUARES_ERR_prod); // statistical uncertainty on lumi-weighted overall pol.


  // numbers for systematics & correction factors
  Int_t year;
  sscanf(filename.Data(),"pol_%d.root",&year);
  Int_t NFILLS_AN_blue, NFILLS_AN_yell;
  Float_t SYS_SCALE_blue;
  Float_t SYS_SCALE_yell;
  Float_t SYS_SCALE_prod;
  switch(year) {
    case 12:
      NFILLS_AN_blue = 49;
      NFILLS_AN_yell = 49;
      SYS_SCALE_blue = 0.034;
      SYS_SCALE_yell = 0.034;
      SYS_SCALE_prod = 0.066;
      break;
    case 13:
      NFILLS_AN_blue = 138;
      NFILLS_AN_yell = 139;
      SYS_SCALE_blue = 0.032;
      SYS_SCALE_yell = 0.033;
      SYS_SCALE_prod = 0.064;
      break;
    default:
      fprintf(stderr,"ERROR: unknown year\n");
      return;
  };
  Float_t SYS_PROFILE_single = 0.022 / TMath::Sqrt(NFILLS);
  Float_t SYS_PROFILE_double = 0.031 / TMath::Sqrt(NFILLS);


  // overcounting correction
  Double_t SIGMA_POL_CORR_blue = SIGMA_POL_blue * ( NFILLS < NFILLS_AN_blue ? (TMath::Sqrt(1-((Float_t)NFILLS)/((Float_t)NFILLS_AN_blue))) : 0.0 );
  Double_t SIGMA_POL_CORR_yell = SIGMA_POL_yell * ( NFILLS < NFILLS_AN_yell ? (TMath::Sqrt(1-((Float_t)NFILLS)/((Float_t)NFILLS_AN_yell))) : 0.0 );
  Double_t SIGMA_POL_CORR_prod = SIGMA_POL_prod * ( NFILLS < NFILLS_AN_blue ? (TMath::Sqrt(1-((Float_t)NFILLS)/((Float_t)NFILLS_AN_blue))) : 0.0 )
                                                * ( NFILLS < NFILLS_AN_yell ? (TMath::Sqrt(1-((Float_t)NFILLS)/((Float_t)NFILLS_AN_yell))) : 0.0 );

  // quadrature sum with systematics
  Double_t SIGMA_POL_TOT_blue = TMath::Sqrt( TMath::Power(SIGMA_POL_CORR_blue, 2) + 
                                             TMath::Power(POL_blue * SYS_SCALE_blue, 2) +
                                             TMath::Power(POL_blue * SYS_PROFILE_single, 2));
  Double_t SIGMA_POL_TOT_yell = TMath::Sqrt( TMath::Power(SIGMA_POL_CORR_yell, 2) + 
                                             TMath::Power(POL_yell * SYS_SCALE_yell, 2) +
                                             TMath::Power(POL_yell * SYS_PROFILE_single, 2));
  Double_t SIGMA_POL_TOT_prod = TMath::Sqrt( TMath::Power(SIGMA_POL_CORR_prod, 2) + 
                                             TMath::Power(POL_prod * SYS_SCALE_prod, 2) +
                                             TMath::Power(POL_prod * SYS_PROFILE_double, 2));


  // print out for latex
  printf("\n\n\n");
  printf("\\begin{aligned}\n");

  printf("& \\text{RUN}~%d \\\\\\\\\n",year);

  printf("& L_{int} = %.4f~\\text{pb}^{-1} \\\\\\\\\n",INT_LUMI);

  printf("& \\mathbb{P}_B = %.4f~~~\\sigma_{\\mathbb{P}_B} = %.4f \\\\\n",POL_blue,SIGMA_POL_TOT_blue);
  printf("& \\mathbb{P}_Y = %.4f~~~\\sigma_{\\mathbb{P}_Y} = %.4f \\\\\n",POL_yell,SIGMA_POL_TOT_yell);
  printf("& \\mathbb{P}_B\\mathbb{P}_Y = %.4f~~~\\sigma_{\\mathbb{P}_B\\mathbb{P}_Y} = %.4f \\\\\\\\\n",POL_prod,SIGMA_POL_TOT_prod);

  printf("& \\sigma_{\\mathbb{P}_B,\\text{(fill-to-fill scale)}} = Re\\left[\\sqrt{1-%d/%d}\\right]\\cdot \\left[%.4f\\right] = %.4f \\\\\n",
    NFILLS,NFILLS_AN_blue,SIGMA_POL_blue,SIGMA_POL_CORR_blue);
  printf("& \\sigma_{\\mathbb{P}_Y,\\text{(fill-to-fill scale)}} = Re\\left[\\sqrt{1-%d/%d}\\right]\\cdot \\left[%.4f\\right] = %.4f \\\\\n",
    NFILLS,NFILLS_AN_yell,SIGMA_POL_yell,SIGMA_POL_CORR_yell);
  printf("& \\sigma_{\\mathbb{P}_B\\mathbb{P}_Y,\\text{(fill-to-fill scale)}} = Re\\left[\\sqrt{1-%d/%d}\\right]\\cdot Re\\left[\\sqrt{1-%d/%d}\\right]\\cdot \\left[%.4f\\right] = %.4f \\\\\\\\\n",
    NFILLS,NFILLS_AN_blue,NFILLS,NFILLS_AN_yell,SIGMA_POL_prod,SIGMA_POL_CORR_prod);

  printf("& \\mathbb{P}_B\\cdot\\sigma_{scale}(P_B)/P_B = %.4f \\cdot %.4f = %.4f \\\\\n",POL_blue,SYS_SCALE_blue,POL_blue*SYS_SCALE_blue);
  printf("& \\mathbb{P}_Y\\cdot\\sigma_{scale}(P_Y)/P_Y = %.4f \\cdot %.4f = %.4f \\\\\n",POL_yell,SYS_SCALE_yell,POL_yell*SYS_SCALE_yell);
  printf("& \\mathbb{P}_B\\mathbb{P}_Y\\cdot\\sigma_{scale}(P_BP_Y)/P_BP_Y = %.4f \\cdot %.4f = %.4f \\\\\\\\\n",
    POL_prod,SYS_SCALE_prod,POL_prod*SYS_SCALE_prod);

  printf("& \\mathbb{P}_B\\cdot\\sigma_{profile}(P_B)/P_B = %.4f \\cdot %.4f = %.4f \\\\\n",POL_blue,SYS_PROFILE_single,POL_blue*SYS_PROFILE_single);
  printf("& \\mathbb{P}_Y\\cdot\\sigma_{profile}(P_Y)/P_Y = %.4f \\cdot %.4f = %.4f \\\\\n",POL_yell,SYS_PROFILE_single,POL_yell*SYS_PROFILE_single);
  printf("& \\mathbb{P}_B\\mathbb{P}_Y\\cdot\\sigma_{profile}(P_BP_Y)/P_BP_Y = %.4f \\cdot %.4f = %.4f \\\\\\\\\n",
    POL_prod,SYS_PROFILE_double,POL_prod*SYS_PROFILE_double);
  printf("\\end{aligned}\n");

};
