#include <assert.h>
#include <time.h>
#include <string.h>

#include "keys2a.h"
#include "mex.h"

// Inputs: file.key
// Outputs: matches
void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]) {
  if(nrhs != 1) {
    mexErrMsgTxt("Error: 1 arg. needed.");
    return;
  }

  char keyfile[1024];
  mxGetString(prhs[0],keyfile,1024);

  double ratio = 0.6f;

  char str[1024];
  strcpy(str,keyfile);
  strcat(str,".gz");
  FILE *FP = fopen(str,"r");
  if(FP==NULL) {
    fprintf(stdout,"%s\n",str);
    fflush(stdout);
    mexErrMsgTxt("File does not exist\n");
    return;
  }
  fclose(FP);

  unsigned char *keys = NULL;
  keypt_t *info = NULL;
  int num_keys = ReadKeyFile(keyfile,&keys,&info);

//   fprintf(stdout,"num_keys: %d\n",num_keys);
//   fflush(stdout);

  plhs[0] = mxCreateNumericMatrix(4,num_keys,mxSINGLE_CLASS,mxREAL);
  float *locs_out = (float*)mxGetData(plhs[0]);
  plhs[1] = mxCreateNumericMatrix(128,num_keys,mxUINT8_CLASS,mxREAL);
  unsigned char *keys_out = (unsigned char*)mxGetData(plhs[1]);
  
  int p = 0;
  for(int i = 0; i < num_keys; i++) {
    locs_out[p++] = info[i].x;
    locs_out[p++] = info[i].y;
    locs_out[p++] = info[i].scale;
    locs_out[p++] = info[i].orient;
  }
  for(int i = 0; i < 128*num_keys; i++) keys_out[i] = keys[i];

  delete [] keys;
  delete [] info;
}
