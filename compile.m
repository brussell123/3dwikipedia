function compile

homedir = pwd;

try
  c = computer; % Get computer type
  
  % Compile ANN:
  cd('./code/LIBS/bundler-v0.4-source/lib/ann_1.1_char');
  switch c
   case 'MACI'
    system('make macosx-g++');
   case 'GLNXA64'
    mkdir('./lib');
    system('make linux64-g++')
   otherwise
    error('Cannot handle this system');
  end
  cd(homedir);

  % Compile needed object file for kd-tree matching:
  cd('./code/LIBS/bundler-v0.4-source/src');
  switch c
   case 'MACI'
    system('gcc -c keys2a.cpp -m32 -I../lib/ann_1.1_char/include -L../lib/ann_1.1_char/lib');
   case 'GLNXA64'
    system('gcc -c keys2a.cpp -fPIC -I../lib/ann_1.1_char/include -L../lib/ann_1.1_char/lib');
  end
  cd(homedir);

  % Compile mex files:
  cd('./code');
  mex mex_keyMatch.cpp ./LIBS/bundler-v0.4-source/src/keys2a.o -I./LIBS/bundler-v0.4-source/lib/ann_1.1_char/include -I./LIBS/bundler-v0.4-source/src -L./LIBS/bundler-v0.4-source/lib/ann_1.1_char/lib -lANN_char -lz
  mex mex_readSIFT.cpp ./LIBS/bundler-v0.4-source/src/keys2a.o -I./LIBS/bundler-v0.4-source/lib/ann_1.1_char/include -I./LIBS/bundler-v0.4-source/src -L./LIBS/bundler-v0.4-source/lib/ann_1.1_char/lib -lANN_char -lz
  cd(homedir);

  % Compile VLfeat (needed for linux):
  switch c
   case 'GLNXA64'
    cd('./code/LIBS/vlfeat-0.9.16');
    MEXPATH = fullfile(matlabroot,'bin','mex');
    system(sprintf('make MEX=%s',MEXPATH));
    cd(homedir);
  end
  
catch
  cd(homedir);
end

