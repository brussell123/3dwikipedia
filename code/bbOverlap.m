function relativeOverlap = bbOverlap(bb1,bb2)
% Inputs:
% bb1
% bb2
%
% Outputs:
% relativeOverlap

bi = [max(bb1(1),bb2(1)) min(bb1(2),bb2(2)) max(bb1(3),bb2(3)) min(bb1(4),bb2(4))];
w=bi(2)-bi(1)+1;
h=bi(4)-bi(3)+1;
if (w>0) && (h>0)
  ua = (bb1(2)-bb1(1)+1)*(bb1(4)-bb1(3)+1) + (bb2(2)-bb2(1)+1)*(bb2(4)-bb2(3)+1) - w*h;
  relativeOverlap = w*h/ua;
else
  relativeOverlap = 0;
end

% $$$ % Convert bb to polygons:
% $$$ x1 = [bb1(1) bb1(2) bb1(2) bb1(1) bb1(1)];
% $$$ y1 = [bb1(3) bb1(3) bb1(4) bb1(4) bb1(3)];
% $$$ x2 = [bb2(1) bb2(2) bb2(2) bb2(1) bb2(1)];
% $$$ y2 = [bb2(3) bb2(3) bb2(4) bb2(4) bb2(3)];
% $$$ 
% $$$ % Make clockwise:
% $$$ [x1,y1] = poly2cw(x1,y1);
% $$$ [x2,y2] = poly2cw(x2,y2);
% $$$ 
% $$$ % Compute overlap:
% $$$ [xi,yi] = polybool('intersection',x1,y1,x2,y2);
% $$$ % $$$ [xu,yu] = polybool('union',x1,y1,x2,y2);
% $$$ % $$$ relativeOverlap = polyarea(xi,yi)/(polyarea(xu,yu)+eps);
% $$$ ai = polyarea(xi,yi);
% $$$ a1 = polyarea(x1,y1);
% $$$ a2 = polyarea(x2,y2);
% $$$ relativeOverlap = ai/(a1+a2-ai+eps);
