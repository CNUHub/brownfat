% matlab script to calculate 0.05 cuttoff and resulting means
% requires normalized 1D images to already exist -- bld_1D_pet_data.bsh 
% must be run from directory above scan directoies

% top directory with containing links to subject directories
study_data_dir='/data/luria/experiments/brownfat/';
% file name extension with naming convention common to files processed the same way
common_file_extension='_gs1p5_nrm20k_noface_adipose_oneD.spr';

% list of subject scans with info needed to build paths to templated files

subjectorcontrol=['Cntrl' ;'Cntrl' ;'Cntrl' ;'Cntrl' ;'Cntrl' ;'Cntrl' ;'Cntrl' ;'Fibro' ;'Fibro' ;'Cntrl' ;'Fibro' ;'Fibro' ;'Cntrl' ;'Cntrl' ;'Cntrl' ;'Fibro' ;'Fibro' ;'Fibro' ;'Fibro' ;'Fibro' ;'Fibro' ;'Fibro' ;'Fibro' ;'Fibro' ];
warmstudylist=   ['E00102';'E00301';'E00602';'E00702';'E00801';'E00901';'E01002';'E01101';'E01201';'E01402';'E02002';'E02102';'E02301';'E02401';'E02502';'E02702';'E02901';'E03001';'E03502';'E03601';'E03702';'E03802';'E03901';'E04102'];
warmserieslist=  ['s102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's103';  's102';  's102';  's103';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102'];
coldstudylist=   ['E00101';'E00302';'E00601';'E00701';'E00802';'E00902';'E01001';'E01102';'E01202';'E01401';'E02001';'E02101';'E02302';'E02402';'E02501';'E02701';'E02902';'E03002';'E03501';'E03602';'E03701';'E03801';'E03902';'E04101'];
coldserieslist=  ['s102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's103';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102';  's102'];


allwarmdata=[];
for i=[1:1:size(warmstudylist)]
  
  warmstudy=warmstudylist(i,:); warmseries=warmserieslist(i,:);
  coldstudy=coldstudylist(i,:); coldseries=coldserieslist(i,:);

% build complate warm image path
  warmonedfile=[study_data_dir warmstudy '/normalized/' warmstudy warmseries common_file_extension];
  fid=fopen(warmonedfile);
  clear warmdata;
  warmdata=fread(fid,'float32','b');
  fclose(fid);

  allwarmdata=[allwarmdata; warmdata];

end

maxbins=5:10:57000;
h=hist(allwarmdata,maxbins);
%bar(maxbin,h)
pdf=fliplr(cumsum(fliplr(h)))/sum(h);

for i=1:1:size(pdf,2)
if(pdf(i) < 0.05)
break
end
end

cutoffvalue=maxbins(i);

fprintf('cutoffvalue=%d\n',cutoffvalue);

% now that we have a cutoff calculate each subjects mean adipose PET value above this threshold

for i=[1:1:size(warmstudylist)]
  
  warmstudy=warmstudylist(i,:); warmseries=warmserieslist(i,:);
  coldstudy=coldstudylist(i,:); coldseries=coldserieslist(i,:);

% build complate warm image path
  warmonedfile=[study_data_dir warmstudy '/normalized/' warmstudy warmseries common_file_extension];
  fid=fopen(warmonedfile);
  clear warmdata;
  warmdata=fread(fid,'float32','b');
  fclose(fid);

% build complate cold image path
  coldonedfile=[study_data_dir coldstudy '/normalized/' coldstudy coldseries common_file_extension];
  fid=fopen(coldonedfile);
  clear colddata;
  colddata=fread(fid,'float32','b');
  fclose(fid);

  warmmean=mean(warmdata(warmdata>cutoffvalue));
  warmcount=sum(warmdata>cutoffvalue);
  coldmean=mean(colddata(colddata>cutoffvalue));
  coldcount=sum(colddata>cutoffvalue);
  fprintf('%s 0.05 cutoff: %d warm %s mean: %f count: %f cold %s mean: %f count: %f cold-warm: %f\n', subjectorcontrol(i,:), cutoffvalue, warmstudy, warmmean, warmcount, coldstudy, coldmean, coldcount, coldmean-warmmean);
end
