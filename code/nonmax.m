function DET = nonmax(DET,obj_np,options)
% Inputs:
% DET - Detection windows.
%
% Outputs:
% DET - Detection windows after nonmax suppression.

if nargin < 3
  options.strmatch = 'noisy'; % or 'exact'
end

windowOverlap = 0.3;%0.5;

% Sort detections by confidence:
[v,nSort] = sort([DET(:).conf],'descend');
DET = DET(nSort);

i = 0;
while i < length(DET)-1
  i = i+1;
% $$$   display(sprintf('%d out of %d',i,length(DET)));

% $$$   if strcmp(DET(i).obj_name,'altar')
% $$$     keyboard;
% $$$   end

  % Get document and word IDs:
  ndx_obj_np = DET(i).ndx_obj_np;
  id_i = []; doc_i = [];
  for k = 1:length(obj_np(ndx_obj_np).obj)
    id_i{k} = [obj_np(ndx_obj_np).obj{k}(:).id];
    doc_i{k} = [obj_np(ndx_obj_np).obj{k}(:).document_id];
  end
  
  n = [];
  for j = i+1:length(DET)

    % Check document and word IDs for jth detection:
    ndx_obj_np = DET(j).ndx_obj_np;
    for k = 1:length(obj_np(ndx_obj_np).obj)
      id_j = [obj_np(ndx_obj_np).obj{k}(:).id];
      doc_j = [obj_np(ndx_obj_np).obj{k}(:).document_id];
      for kk = 1:length(id_i)
        if any(ismember(doc_j,doc_i{kk})&ismember(id_j,id_i{kk}))
          n(end+1) = j;
          break;
        end
      end
    end

    
    if strcmp(DET(i).obj_name,DET(j).obj_name)
      n(end+1) = j;
    else
      ov = bbOverlap(DET(i).bb,DET(j).bb);
      if ov>=windowOverlap && IsCenterInside(DET(i).bb,DET(j).bb) && IsCenterInside(DET(j).bb,DET(i).bb)
        
        n(end+1) = j;

% $$$         % Compare tags:
% $$$         switch options.strmatch
% $$$          case 'noisy'
% $$$           [precision,recall,f,ndx] = CompareTags(DET(i).obj_name,DET(j).obj_name);
% $$$          case 'exact'
% $$$           f = strcmp(CleanString(DET(i).obj_name),CleanString(DET(j).obj_name));
% $$$          otherwise
% $$$           error('invalid options.strmatch');
% $$$         end
% $$$         
% $$$         if f > 0
% $$$           n(end+1) = j;
% $$$         end
      end
    end
  end
  DET(n) = [];
end

return;



function DET = nonmax_v01(DET,options)
% Inputs:
% DET - Detection windows.
%
% Outputs:
% DET - Detection windows after nonmax suppression.

if nargin < 2
  options.strmatch = 'noisy'; % or 'exact'
end

windowOverlap = 0.3;%0.5;

% Sort detections by confidence:
[v,nSort] = sort([DET(:).conf],'descend');
DET = DET(nSort);

i = 0;
while i < length(DET)-1
  i = i+1;
% $$$   display(sprintf('%d out of %d',i,length(DET)));
  n = [];
  for j = i+1:length(DET)
    ov = bbOverlap(DET(i).bb,DET(j).bb);
    if ov>=windowOverlap && IsCenterInside(DET(i).bb,DET(j).bb) && IsCenterInside(DET(j).bb,DET(i).bb)
      % Compare tags:
      switch options.strmatch
       case 'noisy'
        [precision,recall,f,ndx] = CompareTags(DET(i).obj_name,DET(j).obj_name);
       case 'exact'
        f = strcmp(CleanString(DET(i).obj_name),CleanString(DET(j).obj_name));
       otherwise
        error('invalid options.strmatch');
      end

      if f > 0
        n(end+1) = j;
      end
    end
  end
  DET(n) = [];
end
