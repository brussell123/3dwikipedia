function VisualizeDetections(DET,sceneview,GT,options)

% options.N_SEARCHTERMS

if isstr(sceneview)
  sceneview = getfield(load(sceneview),'sceneview');
end

if nargin < 4
  options = struct;
end
if nargin < 3
  GT = [];
end

if ~isfield(options,'N_SEARCHTERMS')
  options.N_SEARCHTERMS = 1000;
end
if ~isfield(options,'plottype')
  options.plottype = 'full'; % 'full' | 'gt' | 'gt+correct' | 'correct' | 'correct+falsepositives' | 'gt+notext' | 'correct+notext' | 'correct+falsepositives+notext'
end
if ~isfield(options,'y_offset')
% $$$   options.y_offset = -50; % Y-offset for text label
  options.y_offset = -0.03; % Y-offset for text label
end
if ~isfield(options,'fontsize')
  options.fontsize = 10;
end
if ~isfield(options,'linewidth')
  options.linewidth = 2;
end
if ~isfield(options,'display_gt')
  options.display_gt = 0;
end
if ~isfield(options,'display_correct')
  options.display_correct = 0;
end
if ~isfield(options,'display_falsepositives')
  options.display_falsepositives = 0;
end

options.y_offset = options.y_offset*max(size(sceneview.img)); % Y-offset for text label

C=DET;

%% PLOT CENTERS
N_RESULTS = min(numel(C),uint8(1.5*options.N_SEARCHTERMS/100));
C=C(1:N_RESULTS);

%display(N_RESULTS);

% Insert default values for missing fields, if any:
if ~isfield(C(1),'issynonym')
  for i = 1:numel(C)
    C(i).issynonym = false;
  end
end
if ~isfield(C(1),'iscorrect')
  for i = 1:numel(C)
    C(i).iscorrect = true;
  end
end

for i=1:numel(C)
    C(i).issynonym = ~isempty(C(i).issynonym) && C(i).issynonym;
    C(i).iscorrect = ~isempty(C(i).iscorrect) && C(i).iscorrect;
end

maxThickness = 12;
colors = hsv(10);
% $$$ axes('position',[0 0 1 1]);
imshow(sceneview.img);
hold on;

if ismember(options.plottype,{'full','gt+correct','gt','gt+notext'})
  %Plot ground truth:
  x_gt = [];
  n_gt = [];
  misses = ~ismember(1:numel(GT),[C.iscorrect]);
  for j = 1:numel(GT)
    PlotBB(GT(j).bb,'k','LineWidth',2*options.linewidth);
    PlotBB(GT(j).bb,'y','LineWidth',options.linewidth);
    x_gt(:,end+1) = [mean(GT(j).bb(1:2)); GT(j).bb(4)+options.y_offset];
    n_gt(end+1) = j;
  end
end

if ismember(options.plottype,{'full','gt+correct','correct','correct+falsepositives','correct+notext','correct+falsepositives+notext'})
  % Plot bounding boxes:
  x_text = [];
  n_text = [];
  text_colors = [];
  pp = 0;
  for i = 1:numel(C)
    if C(i).iscorrect
      box_color = [0 1 0];
      line_width = options.linewidth;%3;
    elseif ismember(options.plottype,{'full','correct+falsepositives','correct+falsepositives+notext'})
      box_color = [1 0 0];
      line_width = options.linewidth/3;%1;
    else
      continue;
    end
    pp = mod(pp,size(colors,1))+1;
    %num_obj = length(C(i).obj_names);
    if ~C(i).issynonym
      PlotBB(C(i).bb,'Color',box_color,'LineWidth',line_width); %,'LineWidth',min(100,num_obj)/100*maxThickness);
    end
    x_text(:,end+1) = [mean(C(i).bb(1:2)); C(i).bb(4)+options.y_offset];
% $$$     x_text(:,end+1) = [mean(C(i).bb(1:2)); C(i).bb(3)+options.y_offset];
% $$$   x_text(:,end+1) = [mean(C(i).bb([1 2])); mean(C(i).bb([3 4]))];
    n_text(end+1) = i;
    text_colors(end+1,:) = colors(pp,:);
  end
end

if ismember(options.plottype,{'gt'}) || options.display_gt
  % Sort from left to right:
  [v,n] = sort(x_gt(1,:));
  x_gt = x_gt(:,n);
  n_gt = n_gt(n);
  
  % Plot ground truth labels:
  for i = 1:size(x_gt,2)
% $$$     labeltext = GT(n_gt(i)).obj_name;
    labeltext = regexp(GT(n_gt(i)).obj_name,',','split');
    labeltext = labeltext{1};
    if ismember(options.plottype,{'gt'})
      text(x_gt(1,i),x_gt(2,i),labeltext,'Color',[0.99 0.99 0.99],'BackgroundColor',[0 0 0],'FontSize',options.fontsize,'HorizontalAlignment','center','Margin',1);
    elseif options.display_gt
      fprintf(options.display_gt,'%s\n',labeltext);
    end
  end
end

if ismember(options.plottype,{'full','gt+correct','correct','correct+falsepositives'}) || options.display_correct
  % Sort from left to right:
  [v,n] = sort(x_text(1,:));
  x_text = x_text(:,n);
  n_text = n_text(n);
  
  %Plot bounding box labels:
  for i = 1:length(n_text)%numel(C)
    C(n_text(i)).obj_name = strtok(C(n_text(i)).obj_name,',');
    textboxcolor = [0 0 0];

% $$$     if C(n_text(i)).iscorrect
% $$$       textboxcolor = [0 1 0];
% $$$     else
% $$$       textboxcolor = [1 0 0];
% $$$     end
% $$$     text(x_text(1,i),x_text(2,i),C(n_text(i)).obj_name,'BackgroundColor',textboxcolor,'FontSize',10);
    
    labeltext = C(n_text(i)).obj_name;
% $$$     disp([ labeltext '. ' C(n_text(i)).obj_name]);
    if C(n_text(i)).iscorrect && ~C(n_text(i)).issynonym
      if ismember(options.plottype,{'full','gt+correct','correct','correct+falsepositives'})
        text(x_text(1,i),x_text(2,i),labeltext,'Color',[0.99 0.99 0.99],'BackgroundColor',[0 0 0],'FontSize',options.fontsize,'HorizontalAlignment','center','Margin',1);
      elseif options.display_correct
        fprintf(options.display_correct,'%s\n',labeltext);
      end
    end
  end
end

