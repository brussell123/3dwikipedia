function DET = InferDetections(DET,model,obj_np,ParseTrees)
% Inputs:
% DET
% model
%
% Outputs:
% DET

X = GetFeatures(DET,DET,obj_np,ParseTrees,model);
conf = model.weights'*X + model.bias;
for i = 1:length(DET)
  DET(i).conf = conf(i);
end

% Perform nonmax suppression:
DET = nonmax(DET,obj_np);

