#cmakedefine STDC_HEADERS

#cmakedefine HAVE_STDINT_H
#cmakedefine HAVE_ERRNO_H
#cmakedefine HAVE_INTTYPES_H
#cmakedefine HAVE_FCNTL_H
#cmakedefine HAVE_LIMITS_H
#cmakedefine HAVE_UNISTD_H

#cmakedefine HAVE_NASM
#cmakedefine HAVE_XMMINTRIN_H

#cmakedefine HAVE_INT8_T
#ifndef HAVE_INT8_T
	typedef short int8_t;
#endif

#cmakedefine HAVE_INT16_T
#ifndef HAVE_INT16_T
	typedef short int16_t;
#endif

#cmakedefine HAVE_INT32_T
#ifndef HAVE_INT32_T
	typedef short int32_t;
#endif

#cmakedefine HAVE_INT64_T
#ifndef HAVE_INT64_T
	typedef short int64_t;
#endif

/* add ieee754_float32_t type */
#undef HAVE_IEEE754_FLOAT32_T
#ifndef HAVE_IEEE754_FLOAT32_T
	typedef float ieee754_float32_t;
#endif

/* add ieee754_float64_t type */
#undef HAVE_IEEE754_FLOAT64_T
#ifndef HAVE_IEEE754_FLOAT64_T
	typedef double ieee754_float64_t;
#endif

/* system has 80 bit floats */
#undef HAVE_IEEE854_FLOAT80

/* add ieee854_float80_t type */
#undef HAVE_IEEE854_FLOAT80_T
#ifndef HAVE_IEEE854_FLOAT80_T
	typedef long double ieee854_float80_t;
#endif

#cmakedefine HAVE_STRCHR
#cmakedefine HAVE_MEMCPY
