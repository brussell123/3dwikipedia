function isTrue = IsCenterInside(bb1,bb2)
% Is center of bb1 inside bb2?
  
cx = mean(bb1(1:2));
cy = mean(bb1(3:4));

isTrue = (bb2(1)<=cx)&(cx<=bb2(2))&(bb2(3)<=cy)&(cy<=bb2(4));
