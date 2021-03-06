if 1

%to generate the codes run in a shell the following command:
%for f in *.csv ; do head -n 1 $f | sed 's/\,D_/\, /g' | sed  's/MOLECULE\,Act\, //' > featurecode/${f%.csv}.csv ; done
close all
clear all

folder='/misc/vlgscratch3/LecunGroup/mbhenaff/merck/merck/paper/train/';

d=dir(folder);
maxfeat = 1;
stdev_norm = 0;


for i=3:length(d)
 fname = d(i).name;
 if(length(fname)>5)
 if(strcmp( fname(end-4:end), 'n.csv')==1)
	code = csvread(fullfile(folder,'featurecode',fname));
	maxfeat = max(maxfeat,max(code(:)));
 end
end
end	
maxfeat

j1 = 32;
opts.kNN=j1;opts.alpha=1;opts.kNNdelta=j1;
bigkern = zeros(maxfeat,'single');
bigmass = zeros(maxfeat,'single');
for i=3:length(d)
 fname = d(i).name;
 if(length(fname)>5)
 if(strcmp( fname(end-4:end), 'n.csv')==1)
	aux = csvread(fullfile(folder,fname),1,3);
	code = csvread(fullfile(folder,'featurecode',fname));
	if stdev_norm
	%normalize each feature
		auxn = sqrt(sum(aux.^2));
		aux = aux./repmat(auxn,size(aux,1),1);
	else %use logarithmic normalizxation
		aux = log(1 + aux);
	end

	auxk = kernelization(aux');
	kersolo{i} = fgf_weights(auxk,opts);
	bigkern(code,code) = bigkern(code,code) + auxk;
	bigmass(code,code) = bigmass(code,code) + size(aux,1);
	fprintf('done dataset %s \n', fname)
 end
end
end

end

ker = bigkern./max(1,bigmass);
poolsize = 8;
poolstride = 4;

for i=3:length(d)
 fname = d(i).name;
 if(length(fname)>5)
 if(strcmp( fname(end-4:end), 'n.csv')==1)
	code = csvread(fullfile(folder,'featurecode',fname));
	kerb= ker(code,code);
	%codef{i} = code;
	kerf=fgf_weights(kerb,opts);	
	D = diag(sum(kerf).^(-1/2));
	L = eye(size(kerf,1)) - D * kerf * D;
	L = (L + L')/2;
	[ee,ev]=eig(L);
  	[V,pools] = ms_spectral_clustering(kerb,kerb,1,1/poolstride,poolsize);
	if stdev_norm
	save(fullfile(folder,sprintf('/graph_%s_std_%d.mat',fname(1:end-4),i)),'kerf','code','L','ee','ev','pools','-v7.3');
	else
	save(fullfile(folder,sprintf('/graph_%s_log_%d.mat',fname(1:end-4),i)),'kerf','code','L','ee','ev','pools','-v7.3');
	end
end
end
end
cd(folder);unix('chmod 777 *');


