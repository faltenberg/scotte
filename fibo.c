#include <stdlib.h>
#include <stdio.h>


int fibo(int n) {
  int f1 = 0;
  int f2 = 1;
  // for (int i = 1; i <= n; i++)
  while (1 <= n) {
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
