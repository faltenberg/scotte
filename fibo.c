#include <stdlib.h>
#include <stdio.h>


int fibo(int n) {
  int f1 = 1;
  int f2 = 1;
  while (n >= 2) {
    int f = f1 + f2;
    f2 = f1;
    f1 = f;
    --n;
  }
  return f1;
}


int main(int argc, char** argv) {
  if (argc != 2) {
    return -1;
  }
  int n = atoi(argv[1]);
  int result = fibo(n);
  printf("fibo(%d) = %d\n", n, result);
  return 0;
}
