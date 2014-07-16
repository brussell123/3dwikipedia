function w = RTow(R)

[U,S,V] = svd(R-eye(3));
vv = V(:,3);
vv = vv/sqrt(vv'*vv);
vvhat = [R(3,2)-R(2,3) R(1,3)-R(3,1) R(2,1)-R(1,2)]';
ang = atan2(vv'*vvhat,trace(R)-1);
w = ang*vv;
