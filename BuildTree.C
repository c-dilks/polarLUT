void BuildTree(Int_t debug=0, 
               TString outfile_n = "pol_12.root",
               TString filename = "polar_by_run.dat") {
  TFile * outfile = new TFile(outfile_n.Data(),"RECREATE");
  TTree * poltr = new TTree();
  TString treestr =
    "i/I:fill/I:runnum/I:startT/I:b_pol/F:b_pol_avg/F:y_pol/F:y_pol_avg/F";
  if(debug) {
    treestr = treestr + 
      ":T/F:midT/F:endT/F:b_p0/F:b_p1/F:y_p0/F:y_p1/F";
  };

  poltr->ReadFile(filename.Data(),treestr.Data());
  poltr->Write("poltr");
  printf("\n%s created\n",outfile_n.Data());
};
