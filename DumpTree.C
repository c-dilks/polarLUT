void DumpTree(TString fname="pol_12.root") {
  TFile * infile = new TFile(fname.Data(),"READ");
  TTree * tr = (TTree*) infile->Get("poltr");
  tr->SetScanField(0);
  TString outname = fname;
  outname.ReplaceAll("root","scan");
  gSystem->RedirectOutput(outname,"w");
  tr->Scan("*");
  gSystem->RedirectOutput(0);
};
