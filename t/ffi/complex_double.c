/*
 * DO NOT MODIFY THIS FILE.
 * This file generated from similar file t/ffi/complex_float.c
 * all instances of "float" have been changed to "double"
 */
#include "libtest.h"
#if SIZEOF_DOUBLE_COMPLEX

EXTERN double
complex_double_get_real(double complex f)
{
  return creal(f);
}

EXTERN double
complex_double_get_imag(double complex f)
{
  return cimag(f);
}

EXTERN const char *
complex_double_to_string(double complex f)
{
  static char buffer[1024];
  sprintf(buffer, "%g + %g * i", creal(f), cimag(f));
  return buffer;
}

EXTERN double
complex_double_ptr_get_real(double complex *f)
{
  return creal(*f);
}

EXTERN double
complex_double_ptr_get_imag(double complex *f)
{
  return cimag(*f);
}

EXTERN void
complex_double_ptr_set(double complex *f, double r, double i)
{
  *f = r + i*I;
}

EXTERN double complex
complex_double_ret(double r, double i)
{
  return r + i*I;
}

EXTERN double complex *
complex_double_ptr_ret(double r, double i)
{
  static double complex f;
  f = r + i*I;
  return &f;
}

EXTERN double complex
complex_double_array_get(double complex *f, int index)
{
  return f[index];
}

EXTERN void
complex_double_array_set(double complex *f, int index, double r, double i)
{
  f[index] = r + i*I;
}

EXTERN double complex *
complex_double_array_ret(void)
{
  static double complex ret[3];

  ret[0] = 0.0 + 0.0*I;
  ret[1] = 1.0 + 2.0*I;
  ret[2] = 3.0 + 4.0*I;

  return ret;
}

#endif
