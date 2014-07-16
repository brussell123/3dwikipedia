function [f,d] = ComputeSIFT(img)

if isunix
  % Use vlfeat:
  vl_setup;
% $$$   img = single(rgb2gray(img)) ;
  [f,d] = vl_sift(single(rgb2gray(img)),'FirstOctave',-1,'edgethresh',10,'peakthresh',3.4) ;
% $$$   [f,d] = vl_sift(single(rgb2gray(img)),'firstoctave', -1,'peakthresh', .01,'edgethresh', 10,'windowsize', 2);
  
  % Convert to UBC format:
  d2 = d;
  p=[1 2 3 4 5 6 7 8] ;
  q=[1 8 7 6 5 4 3 2] ;
  for jj=0:3
    for ii=0:3
      % ubc <-> vl
      d(8*(ii+4*jj)+q,:) = d2(8*(ii+4*jj)+p,:);
    end
  end
  
  
  doDisplay = 0;
  if doDisplay
    perm = randperm(size(f,2)) ;
    sel  = perm(1:50) ;
    figure;
    imagesc(img);
    axis equal ; axis off ; axis tight ;
    hold on;
    h1   = vl_plotframe(f(:,sel)) ; set(h1,'color','k','linewidth',3) ;
    h2   = vl_plotframe(f(:,sel)) ; set(h2,'color','y','linewidth',2) ;

    delete([h1 h2]);
    
    h3 = vl_plotsiftdescriptor(d(:,sel),f(:,sel)) ;
    set(h3,'color','k','linewidth',2) ;
    h4 = vl_plotsiftdescriptor(d(:,sel),f(:,sel)) ;
    set(h4,'color','g','linewidth',1) ;
    h1   = vl_plotframe(f(:,sel)) ; set(h1,'color','k','linewidth',3) ;
    h2   = vl_plotframe(f(:,sel)) ; set(h2,'color','y','linewidth',2) ;
  end
else
  error('Need to add SIFT binary for this operating system.');
end
