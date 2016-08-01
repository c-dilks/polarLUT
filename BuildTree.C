void BuildTree(TString outfile_n = "pol_12.root",
               TString filename = "polar_by_run_with_lumi.dat") {
  TFile * outfile = new TFile(outfile_n.Data(),"RECREATE");

  // build tree
  TTree * poltr = new TTree();
  TString treestr =
    "i/I:fill/I:runnum/I:startT/F:b_pol/F:b_pol_avg/F:y_pol/F:y_pol_avg/F";
  treestr = treestr + ":T/F:midT/F:endT/F:b_p0/F:b_p1/F:y_p0/F:y_p1/F";
  treestr = treestr + ":lumi_run/D:lumi_fill/D:b_pol_lw/D:y_pol_lw/D";
  poltr->ReadFile(filename.Data(),treestr.Data());


  // project
  Int_t imin=0;
  Int_t imax=poltr->GetMaximum("i");
  Int_t ent = poltr->GetEntries();

  TString h_title = "P^{B}(t)[blue] :: <P^{B}>_{beam_current_weighted}[red] :: <P^{B}>_{lumi_weighted}[magenta] :: P^{B}_{0}[green] vs. run index";

  TH1D * h_b_pol = new TH1D("h_b_pol",h_title.Data(),ent,0,imax+1);
  TH1D * h_b_pol_avg = new TH1D("h_b_pol_avg",h_title.Data(),ent,0,imax+1);
  TH1D * h_b_pol_lw = new TH1D("h_b_pol_lw",h_title.Data(),ent,0,imax+1);
  TH1D * h_b_p0 = new TH1D("h_b_p0",h_title.Data(),ent,0,imax+1);
  TH1D * h_b_p1 = new TH1D("h_b_p1","P^{B}_{1} vs. run index",ent,0,imax+1);

  h_title.ReplaceAll("B","Y");

  TH1D * h_y_pol = new TH1D("h_y_pol",h_title.Data(),ent,0,imax+1);
  TH1D * h_y_pol_avg = new TH1D("h_y_pol_avg",h_title.Data(),ent,0,imax+1);
  TH1D * h_y_pol_lw = new TH1D("h_y_pol_lw",h_title.Data(),ent,0,imax+1);
  TH1D * h_y_p0 = new TH1D("h_y_p0",h_title.Data(),ent,0,imax+1);
  TH1D * h_y_p1 = new TH1D("h_y_p1","P^{Y}_{1} vs. run index",ent,0,imax+1);


  TString lumi_title = "Luminsosity vs. run index (by run [blue] :: by fill [orange])";
  TH1D * h_lumi_run = new TH1D("h_lumi_run",lumi_title.Data(),ent,0,imax+1);
  TH1D * h_lumi_fill = new TH1D("h_lumi_fill",lumi_title.Data(),ent,0,imax+1);


  poltr->Project("h_b_pol","i","b_pol");
  poltr->Project("h_b_pol_avg","i","b_pol_avg");
  poltr->Project("h_b_pol_lw","i","b_pol_lw");
  poltr->Project("h_b_p0","i","b_p0");
  poltr->Project("h_b_p1","i","b_p1");

  poltr->Project("h_y_pol","i","y_pol");
  poltr->Project("h_y_pol_avg","i","y_pol_avg");
  poltr->Project("h_y_pol_lw","i","y_pol_lw");
  poltr->Project("h_y_p0","i","y_p0");
  poltr->Project("h_y_p1","i","y_p1");

  poltr->Project("h_lumi_run","i","lumi_run");
  poltr->Project("h_lumi_fill","i","lumi_fill");



  h_b_pol->SetLineColor(kBlue);
  h_b_pol_avg->SetLineColor(kRed+1);
  h_b_pol_lw->SetLineColor(kMagenta);
  h_b_p0->SetLineColor(kGreen+2);
  h_b_p1->SetLineColor(kCyan+1);
  h_b_p1->SetFillColor(kCyan+1);

  h_y_pol->SetLineColor(kBlue);
  h_y_pol_avg->SetLineColor(kRed+1);
  h_y_pol_lw->SetLineColor(kMagenta);
  h_y_p0->SetLineColor(kGreen+2);
  h_y_p1->SetLineColor(kCyan+1);
  h_y_p1->SetFillColor(kCyan+1);

  h_lumi_run->SetLineColor(kBlue);
  h_lumi_run->SetFillColor(kBlue);
  h_lumi_fill->SetLineColor(kOrange+1);
  h_lumi_fill->SetFillColor(kOrange+1);

  const Float_t LWIDTH = 2;
  h_b_pol->SetLineWidth(LWIDTH);
  h_b_pol_avg->SetLineWidth(LWIDTH);
  h_b_pol_lw->SetLineWidth(LWIDTH);
  h_b_p0->SetLineWidth(LWIDTH);
  h_y_pol->SetLineWidth(LWIDTH);
  h_y_pol_avg->SetLineWidth(LWIDTH);
  h_y_pol_lw->SetLineWidth(LWIDTH);
  h_y_p0->SetLineWidth(LWIDTH);

  h_b_pol->GetYaxis()->SetRangeUser(0,100);
  h_b_pol_avg->GetYaxis()->SetRangeUser(0,100);
  h_b_pol_lw->GetYaxis()->SetRangeUser(0,100);
  h_b_p0->GetYaxis()->SetRangeUser(0,100);
  h_y_pol->GetYaxis()->SetRangeUser(0,100);
  h_y_pol_avg->GetYaxis()->SetRangeUser(0,100);
  h_y_pol_lw->GetYaxis()->SetRangeUser(0,100);
  h_y_p0->GetYaxis()->SetRangeUser(0,100);


  // zoom in for printing etc.
  Bool_t zoom = false;
  Int_t lower_bound = 2000;
  Int_t upper_bound = 3000;
  if(zoom)
  {
    h_b_pol->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_b_pol_avg->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_b_p0->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_b_p1->GetXaxis()->SetRangeUser(lower_bound,upper_bound);

    h_y_pol->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_y_pol_avg->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_y_p0->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_y_p1->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
  };


  // draw
  gStyle->SetOptStat(0);
  Int_t width_factor = zoom ? 1:10;
  width_factor = 1; // override, since goodruns.dat filter reduces 
                    // number of runs to ~1000
  TString png_name = zoom ? "canv_blue_zoomed_":"canv_blue_full_";
  png_name = png_name + outfile_n;
  png_name.ReplaceAll("root","png");

  TCanvas * c_b = new TCanvas("canv_blue","canv_blue",width_factor*2500,2000);
  c_b->Divide(1,5);
  c_b->cd(1);
    h_b_pol->Draw();
    h_b_pol_avg->Draw("same");
  c_b->cd(2);
    h_b_pol->Draw();
    h_b_pol_lw->Draw("same");
  c_b->cd(3); 
    h_b_pol->Draw();
    h_b_p0->Draw("same");
  c_b->cd(4); h_b_p1->Draw();
  c_b->cd(5); 
    h_lumi_fill->Draw();
    h_lumi_run->Draw("same");
  c_b->Print(png_name.Data(),"png");


  png_name.ReplaceAll("blue","yell");
  TCanvas * c_y = new TCanvas("canv_yell","canv_yell",width_factor*2500,2000);
  c_y->Divide(1,5);
  c_y->cd(1);
    h_y_pol->Draw();
    h_y_pol_avg->Draw("same");
  c_y->cd(2);
    h_y_pol->Draw();
    h_y_pol_lw->Draw("same");
  c_y->cd(3); 
    h_y_pol->Draw();
    h_y_p0->Draw("same");
  c_y->cd(4); h_y_p1->Draw();
  c_y->cd(5); 
    h_lumi_fill->Draw();
    h_lumi_run->Draw("same");
  c_y->Print(png_name.Data(),"png");



  // write
  poltr->Write("poltr");
  c_b->Write();
  c_y->Write();
  printf("\n%s created\n",outfile_n.Data());
};
