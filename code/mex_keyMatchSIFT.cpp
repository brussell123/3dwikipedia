#include <assert.h>
#include <time.h>
#include <string.h>

#include "keys2a.h"
#include "mex.h"

// Inputs: keys1 keys2
// Outputs: matches
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) {
  if(nrhs != 2) {
    mexErrMsgTxt("Error: 2 args. needed.");
    return;
  }

  unsigned char *keys1 = (unsigned char*)mxGetData(prhs[0]);
  int num_keys1 = mxGetN(prhs[0]);
  unsigned char *keys2 = (unsigned char*)mxGetData(prhs[1]);
  int num_keys2 = mxGetN(prhs[1]);

  double ratio = 0.6f;

  // Create a tree from the keys
  ANNkd_tree *tree = CreateSearchTree(num_keys2,keys2);

  // Compute likely matches between two sets of keypoints
  std::vector<KeypointMatch> matches = 
    MatchKeys(num_keys1,keys1,tree,ratio);

  int num_matches = (int) matches.size();

//   fprintf(stdout,"num_matches: %d\n",num_matches);
//   fflush(stdout);

  plhs[0] = mxCreateNumericMatrix(2,num_matches,mxINT32_CLASS,mxREAL);
  int *matches_out = (int*)mxGetData(plhs[0]);
  
  int p = 0;
  for(int i = 0; i < num_matches; i++) {
    matches_out[p++] = matches[i].m_idx1+1;
    matches_out[p++] = matches[i].m_idx2+1;
  }

  annDeallocPts(tree->pts);
  delete tree;
}
