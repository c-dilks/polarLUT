void BuildTree(TString outfile_n = "pol_12.root",
               TString filename = "polar_by_run_with_lumi.dat") {
  TFile * outfile = new TFile(outfile_n.Data(),"RECREATE");
  TString outfile_e_n = outfile_n;
  outfile_e_n.ReplaceAll("pol","pol_E");

  // build tree
  TTree * poltr = new TTree();
  TString treestr =
    "i/I:fill/I:runnum/I:startT/F:b_pol/F:b_pol_avg/F:y_pol/F:y_pol_avg/F";
  treestr = treestr + ":T/F:midT/F:endT/F:b_p0/F:b_p1/F:y_p0/F:y_p1/F";
  treestr = treestr + ":b_pol_avg_E/F:b_p0_E/F:b_p1_E/F:b_pol_E/F";
  treestr = treestr + ":y_pol_avg_E/F:y_p0_E/F:y_p1_E/F:y_pol_E/F";
  treestr = treestr + ":lumi_run/D:lumi_fill/D:b_pol_lw/D:y_pol_lw/D:b_pol_lw_E/D:y_pol_lw_E/D:prod_pol_lw/D:prod_pol_lw_E/D";
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

  h_title = "P^{B}P^{Y}(t)[blue] :: <P^{B}P^{Y}>_{beam_current_weighted}[red] :: <P^{B}P^{Y}>_{lumi_weighted}[magenta] vs. run index";

  TH1D * h_by_pol = new TH1D("h_by_pol",h_title.Data(),ent,0,imax+1);
  TH1D * h_by_pol_avg = new TH1D("h_by_pol_avg",h_title.Data(),ent,0,imax+1);
  TH1D * h_by_pol_lw = new TH1D("h_by_pol_lw",h_title.Data(),ent,0,imax+1);

  TString e_title = "#sigma <P^{B}>_{beam_current_weighted}[red] :: #sigma <P^{B}>_{lumi_weighted}[blue] :: #sigma P^{B}_{0}[green] :: #sigma P^{B}_{1}[cyan] vs. run index";

  TH1D * e_b_pol = new TH1D("e_b_pol",e_title.Data(),ent,0,imax+1);
  TH1D * e_b_pol_avg = new TH1D("e_b_pol_avg",e_title.Data(),ent,0,imax+1);
  TH1D * e_b_pol_lw = new TH1D("e_b_pol_lw",e_title.Data(),ent,0,imax+1);
  TH1D * e_b_p0 = new TH1D("e_b_p0",e_title.Data(),ent,0,imax+1);
  TH1D * e_b_p1 = new TH1D("e_b_p1","P^{Y}_{1} vs. run index",ent,0,imax+1);

  e_title.ReplaceAll("B","Y");

  TH1D * e_y_pol = new TH1D("e_y_pol",e_title.Data(),ent,0,imax+1);
  TH1D * e_y_pol_avg = new TH1D("e_y_pol_avg",e_title.Data(),ent,0,imax+1);
  TH1D * e_y_pol_lw = new TH1D("e_y_pol_lw",e_title.Data(),ent,0,imax+1);
  TH1D * e_y_p0 = new TH1D("e_y_p0",e_title.Data(),ent,0,imax+1);
  TH1D * e_y_p1 = new TH1D("e_y_p1","P^{Y}_{1} vs. run index",ent,0,imax+1);

  e_title = "#sigma <P^{B}P^{Y}>_{beam_current_weighted}[red] :: #sigma <P^{B}P^{Y}>_{lumi_weighted}[blue] vs. run index";

  TH1D * e_by_pol_avg = new TH1D("e_by_pol_avg",e_title.Data(),ent,0,imax+1);
  TH1D * e_by_pol_lw = new TH1D("e_by_pol_lw",e_title.Data(),ent,0,imax+1);


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

  poltr->Project("h_by_pol","i","b_pol*y_pol");
  poltr->Project("h_by_pol_avg","i","b_pol_avg*y_pol_avg");
  poltr->Project("h_by_pol_lw","i","prod_pol_lw");

  poltr->Project("e_b_pol","i","b_pol_E");
  poltr->Project("e_b_pol_avg","i","b_pol_avg_E");
  poltr->Project("e_b_pol_lw","i","b_pol_lw_E");
  poltr->Project("e_b_p0","i","b_p0_E");
  poltr->Project("e_b_p1","i","b_p1_E");

  poltr->Project("e_y_pol","i","y_pol_E");
  poltr->Project("e_y_pol_avg","i","y_pol_avg_E");
  poltr->Project("e_y_pol_lw","i","y_pol_lw_E");
  poltr->Project("e_y_p0","i","y_p0_E");
  poltr->Project("e_y_p1","i","y_p1_E");

  poltr->Project("e_by_pol_avg","i","sqrt(b_pol_avg_E*b_pol_avg_E+y_pol_avg_E*y_pol_avg_E)");
  poltr->Project("e_by_pol_lw","i","prod_pol_lw_E");

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

  h_by_pol->SetLineColor(kBlue);
  h_by_pol_avg->SetLineColor(kRed+1);
  h_by_pol_lw->SetLineColor(kMagenta);

  e_b_pol->SetLineColor(kBlue);
  e_b_pol_avg->SetLineColor(kRed+1);
  e_b_pol_lw->SetLineColor(kBlue);
  e_b_p0->SetLineColor(kGreen+2);
  e_b_p1->SetLineColor(kCyan+1);

  e_y_pol->SetLineColor(kBlue);
  e_y_pol_avg->SetLineColor(kRed+1);
  e_y_pol_lw->SetLineColor(kBlue);
  e_y_p0->SetLineColor(kGreen+2);
  e_y_p1->SetLineColor(kCyan+1);

  e_by_pol_avg->SetLineColor(kRed+1);
  e_by_pol_lw->SetLineColor(kBlue);

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
  h_by_pol->SetLineWidth(LWIDTH);
  h_by_pol_avg->SetLineWidth(LWIDTH);
  h_by_pol_lw->SetLineWidth(LWIDTH);

  e_b_pol->SetLineWidth(LWIDTH);
  e_b_pol_avg->SetLineWidth(LWIDTH);
  e_b_pol_lw->SetLineWidth(LWIDTH);
  e_b_p0->SetLineWidth(LWIDTH);
  e_b_p1->SetLineWidth(LWIDTH);
  e_y_pol->SetLineWidth(LWIDTH);
  e_y_pol_avg->SetLineWidth(LWIDTH);
  e_y_pol_lw->SetLineWidth(LWIDTH);
  e_y_p0->SetLineWidth(LWIDTH);
  e_y_p1->SetLineWidth(LWIDTH);
  e_by_pol_avg->SetLineWidth(LWIDTH);
  e_by_pol_lw->SetLineWidth(LWIDTH);

  h_b_pol->GetYaxis()->SetRangeUser(0,1);
  h_b_pol_avg->GetYaxis()->SetRangeUser(0,1);
  h_b_pol_lw->GetYaxis()->SetRangeUser(0,1);
  h_b_p0->GetYaxis()->SetRangeUser(0,1);
  h_y_pol->GetYaxis()->SetRangeUser(0,1);
  h_y_pol_avg->GetYaxis()->SetRangeUser(0,1);
  h_y_pol_lw->GetYaxis()->SetRangeUser(0,1);
  h_y_p0->GetYaxis()->SetRangeUser(0,1);
  h_by_pol->GetYaxis()->SetRangeUser(0,1);
  h_by_pol_avg->GetYaxis()->SetRangeUser(0,1);
  h_by_pol_lw->GetYaxis()->SetRangeUser(0,1);

  e_b_pol->GetYaxis()->SetRangeUser(0,0.2);
  e_b_pol_avg->GetYaxis()->SetRangeUser(0,0.2);
  e_b_pol_lw->GetYaxis()->SetRangeUser(0,0.2);
  e_y_pol->GetYaxis()->SetRangeUser(0,0.2);
  e_y_pol_avg->GetYaxis()->SetRangeUser(0,0.2);
  e_y_pol_lw->GetYaxis()->SetRangeUser(0,0.2);
  e_by_pol_avg->GetYaxis()->SetRangeUser(0,0.2);
  e_by_pol_lw->GetYaxis()->SetRangeUser(0,0.2);


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
    
    h_by_pol->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_by_pol_avg->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
    h_by_p0->GetXaxis()->SetRangeUser(lower_bound,upper_bound);
  };


  // draw
  gStyle->SetOptStat(0);
  Int_t width_factor = zoom ? 1:10;
  width_factor = 1; // override, since goodruns.dat filter reduces 
                    // number of runs to ~1000
  TString png_name = zoom ? "canv_blue_zoomed_":"canv_blue_full_";
  png_name = png_name + outfile_n;
  png_name.ReplaceAll("root","png");

  TCanvas * c_b = new TCanvas("canv_blue","canv_blue",width_factor*2500,5*400);
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
  TCanvas * c_y = new TCanvas("canv_yell","canv_yell",width_factor*2500,5*400);
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


  png_name.ReplaceAll("yell","prod");
  TCanvas * c_by = new TCanvas("canv_prod","canv_prod",width_factor*2500,3*400);
  c_by->Divide(1,3);
  c_by->cd(1);
    h_by_pol->Draw();
    h_by_pol_avg->Draw("same");
  c_by->cd(2);
    h_by_pol->Draw();
    h_by_pol_lw->Draw("same");
  c_by->cd(3); 
    h_lumi_fill->Draw();
    h_lumi_run->Draw("same");
  c_by->Print(png_name.Data(),"png");


  TString png_name_e = zoom ? "canv_blue_zoomed_":"canv_blue_full_";
  png_name_e = png_name_e + outfile_e_n;
  png_name_e.ReplaceAll("root","png");

  TCanvas * ce_b = new TCanvas("canv_blue_err","canv_blue_err",width_factor*2500,4*400);
  ce_b->Divide(1,4);
  /*
  ce_b->cd(1);
    e_b_pol->Draw();
    e_b_pol_avg->Draw("same");
    */
  ce_b->cd(1);
    e_b_pol_avg->Draw();
    e_b_pol_lw->Draw("same");
  ce_b->cd(2); e_b_p0->Draw();
  ce_b->cd(3); e_b_p1->Draw();
  ce_b->cd(4); 
    h_lumi_fill->Draw();
    h_lumi_run->Draw("same");
  ce_b->Print(png_name_e.Data(),"png");

  png_name_e.ReplaceAll("blue","yell");
  TCanvas * ce_y = new TCanvas("canv_yell_err","canv_yell_err",width_factor*2500,4*400);
  ce_y->Divide(1,4);
  /*
  ce_y->cd(1);
    e_y_pol->Draw();
    e_y_pol_avg->Draw("same");
    */
  ce_y->cd(1);
    e_y_pol_avg->Draw();
    e_y_pol_lw->Draw("same");
  ce_y->cd(2); e_y_p0->Draw();
  ce_y->cd(3); e_y_p1->Draw();
  ce_y->cd(4); 
    h_lumi_fill->Draw();
    h_lumi_run->Draw("same");
  ce_y->Print(png_name_e.Data(),"png");

  png_name_e.ReplaceAll("yell","prod");
  TCanvas * ce_by = new TCanvas("canv_prod_err","canv_prod_err",width_factor*2500,2*400);
  ce_by->Divide(1,2);
  ce_by->cd(1);
    e_by_pol_avg->Draw();
    e_by_pol_lw->Draw("same");
  ce_by->cd(2); 
    h_lumi_fill->Draw();
    h_lumi_run->Draw("same");
  ce_by->Print(png_name_e.Data(),"png");

  // write
  poltr->Write("poltr");
  c_b->Write();
  c_y->Write();
  c_by->Write();
  ce_b->Write();
  ce_y->Write();
  ce_by->Write();
  printf("\n%s created\n",outfile_n.Data());
};
