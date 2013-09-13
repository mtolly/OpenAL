
dnl FPTOOLS_HTYPE_INCLUDES
AC_DEFUN([FPTOOLS_HTYPE_INCLUDES],
[
#include <stdio.h>
#include <stddef.h>

#if HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#if HAVE_UNISTD_H
# include <unistd.h>
#endif

#if HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif

#if HAVE_FCNTL_H
# include <fcntl.h>
#endif

#if HAVE_SIGNAL_H
# include <signal.h>
#endif

#if HAVE_TIME_H
# include <time.h>
#endif

#if HAVE_TERMIOS_H
# include <termios.h>
#endif

#if HAVE_STRING_H
# include <string.h>
#endif

#if HAVE_CTYPE_H
# include <ctype.h>
#endif

#if defined(HAVE_GL_GL_H)
# include <GL/gl.h>
#elif defined(HAVE_OPENGL_GL_H)
# include <OpenGL/gl.h>
#endif

#if defined(HAVE_AL_AL_H)
# include <AL/al.h>
#elif defined(HAVE_OPENAL_AL_H)
# include <OpenAL/al.h>
#endif

#if defined(HAVE_AL_ALC_H)
# include <AL/alc.h>
#elif defined(HAVE_OPENAL_ALC_H)
# include <OpenAL/alc.h>
#endif

#if HAVE_SYS_RESOURCE_H
# include <sys/resource.h>
#endif
])

dnl ** Map an arithmetic C type to a Haskell type.
dnl    Based on autconf's AC_CHECK_SIZEOF.

dnl FPTOOLS_CHECK_HTYPE_ELSE(TYPE, WHAT_TO_DO_IF_TYPE_DOES_NOT_EXIST)
AC_DEFUN([FPTOOLS_CHECK_HTYPE_ELSE],[
    changequote(<<, >>)
    dnl The name to #define.
    define(<<AC_TYPE_NAME>>, translit(htype_$1, [a-z *], [A-Z_P]))
    dnl The cache variable names.
    define(<<AC_CV_NAME>>, translit(fptools_cv_htype_$1, [ *], [_p]))
    define(<<AC_CV_NAME_supported>>, translit(fptools_cv_htype_sup_$1, [ *], [_p]))
    changequote([, ])

    AC_MSG_CHECKING(Haskell type for $1)
    AC_CACHE_VAL(AC_CV_NAME,[
        AC_CV_NAME_supported=yes
        FP_COMPUTE_INT([HTYPE_IS_INTEGRAL],
                       [($1)0.2 - ($1)0.4 < 0 ? 0 : 1],
                       [FPTOOLS_HTYPE_INCLUDES],[HTYPE_IS_INTEGRAL=0])

        if test "$HTYPE_IS_INTEGRAL" -eq 0
        then
            FP_COMPUTE_INT([HTYPE_IS_FLOAT],[sizeof($1) == sizeof(float)],
                           [FPTOOLS_HTYPE_INCLUDES],
                           [AC_CV_NAME_supported=no])
            FP_COMPUTE_INT([HTYPE_IS_DOUBLE],[sizeof($1) == sizeof(double)],
                           [FPTOOLS_HTYPE_INCLUDES],
                           [AC_CV_NAME_supported=no])
            FP_COMPUTE_INT([HTYPE_IS_LDOUBLE],[sizeof($1) == sizeof(long double)],
                           [FPTOOLS_HTYPE_INCLUDES],
                           [AC_CV_NAME_supported=no])
            if test "$HTYPE_IS_FLOAT" -eq 1
            then
                AC_CV_NAME=Float
            elif test "$HTYPE_IS_DOUBLE" -eq 1
            then
                AC_CV_NAME=Double
            elif test "$HTYPE_IS_LDOUBLE" -eq 1
            then
                AC_CV_NAME=LDouble
            else
                AC_CV_NAME_supported=no
            fi
        else
            FP_COMPUTE_INT([HTYPE_IS_SIGNED],[(($1)(-1)) < (($1)0)],
                           [FPTOOLS_HTYPE_INCLUDES],
                           [AC_CV_NAME_supported=no])
            FP_COMPUTE_INT([HTYPE_SIZE],[sizeof($1) * 8],
                           [FPTOOLS_HTYPE_INCLUDES],
                           [AC_CV_NAME_supported=no])
            if test "$HTYPE_IS_SIGNED" -eq 0
            then
                AC_CV_NAME="Word$HTYPE_SIZE"
            else
                AC_CV_NAME="Int$HTYPE_SIZE"
            fi
        fi
    ])
    if test "$AC_CV_NAME_supported" = no
    then
        $2
    fi

    dnl Note: evaluating dollar-2 can change the value of
    dnl $AC_CV_NAME_supported, so we might now get a different answer
    if test "$AC_CV_NAME_supported" = yes; then
        AC_MSG_RESULT($AC_CV_NAME)
        AC_DEFINE_UNQUOTED(AC_TYPE_NAME, $AC_CV_NAME,
                           [Define to Haskell type for $1])
    fi
    undefine([AC_TYPE_NAME])dnl
    undefine([AC_CV_NAME])dnl
    undefine([AC_CV_NAME_supported])dnl
])

dnl FPTOOLS_CHECK_HTYPE(TYPE)
AC_DEFUN([FPTOOLS_CHECK_HTYPE],[
    FPTOOLS_CHECK_HTYPE_ELSE([$1],[
        AC_CV_NAME=NotReallyAType
        AC_MSG_RESULT([not supported])
    ])
])

# FP_COMPUTE_INT(EXPRESSION, VARIABLE, INCLUDES, IF-FAILS)
# ---------------------------------------------------------
# Assign VARIABLE the value of the compile-time EXPRESSION using INCLUDES for
# compilation. Execute IF-FAILS when unable to determine the value. Works for
# cross-compilation, too.
#
# Implementation note: We are lazy and use an internal autoconf macro, but it
# is supported in autoconf versions 2.50 up to the actual 2.57, so there is
# little risk.
AC_DEFUN([FP_COMPUTE_INT],
[_AC_COMPUTE_INT([$2], [$1], [$3], [$4])[]dnl
])# FP_COMPUTE_INT

# FP_CHECK_CONST(EXPRESSION, [INCLUDES = DEFAULT-INCLUDES], [VALUE-IF-FAIL = -1])
# -------------------------------------------------------------------------------
# Defines CONST_EXPRESSION to the value of the compile-time EXPRESSION, using
# INCLUDES. If the value cannot be determined, use VALUE-IF-FAIL.
AC_DEFUN([FP_CHECK_CONST],
[AS_VAR_PUSHDEF([fp_Cache], [fp_cv_const_$1])[]dnl
AC_CACHE_CHECK([value of $1], fp_Cache,
[FP_COMPUTE_INT(fp_check_const_result, [$1], [AC_INCLUDES_DEFAULT([$2])],
                [fp_check_const_result=m4_default([$3], ['-1'])])
AS_VAR_SET(fp_Cache, [$fp_check_const_result])])[]dnl
AC_DEFINE_UNQUOTED(AS_TR_CPP([CONST_$1]), AS_VAR_GET(fp_Cache), [The value of $1.])[]dnl
AS_VAR_POPDEF([fp_Cache])[]dnl
])# FP_CHECK_CONST


# FP_CHECK_CONSTS_TEMPLATE(EXPRESSION...)
# ---------------------------------------
# autoheader helper for FP_CHECK_CONSTS
m4_define([FP_CHECK_CONSTS_TEMPLATE],
[AC_FOREACH([fp_Const], [$1],
  [AH_TEMPLATE(AS_TR_CPP(CONST_[]fp_Const),
               [The value of ]fp_Const[.])])[]dnl
])# FP_CHECK_CONSTS_TEMPLATE


# FP_CHECK_CONSTS(EXPRESSION..., [INCLUDES = DEFAULT-INCLUDES], [VALUE-IF-FAIL = -1])
# -----------------------------------------------------------------------------------
# List version of FP_CHECK_CONST
AC_DEFUN([FP_CHECK_CONSTS],
[FP_CHECK_CONSTS_TEMPLATE([$1])dnl
for fp_const_name in $1
do
FP_CHECK_CONST([$fp_const_name], [$2], [$3])
done
])# FP_CHECK_CONSTS


# FP_ARG_OPENAL
# -------------
AC_DEFUN([FP_ARG_OPENAL],
[AC_ARG_ENABLE([openal],
  [AC_HELP_STRING([--enable-openal],
    [build a Haskell binding for OpenAL (default=autodetect)])],
  [enable_openal=$enableval],
  [enable_openal=yes])
])# FP_ARG_OPENAL


# FP_CHECK_OPENAL
# -------------
AC_DEFUN([FP_CHECK_OPENAL],
[AC_REQUIRE([AC_CANONICAL_TARGET])
AL_CFLAGS=
case $target_os in
darwin*)
  AL_LIBS=
  AL_FRAMEWORKS=OpenAL
  ;;
*)
  AC_SEARCH_LIBS([alGenSources], [openal openal32], [AL_LIBS="$ac_cv_search_alGenSources"])
  test x"$AL_LIBS" = x"none required" && AL_LIBS=
  AC_SUBST([AL_LIBS])
  AL_FRAMEWORKS=
  ;;
esac
AC_SUBST([AL_CFLAGS])
AC_SUBST([AL_FRAMEWORKS])
])# FP_CHECK_OPENAL


# FP_HEADER_AL
# ------------
# Check for an AL header, setting the variable fp_found_al_header to no/yes,
# depending on the outcome.
AC_DEFUN([FP_HEADER_AL],
[if test -z "$fp_found_al_header"; then
  fp_found_al_header=no
  AC_CHECK_HEADERS([AL/al.h OpenAL/al.h], [fp_found_al_header=yes; break])
fi
]) # FP_HEADER_AL


# FP_HEADER_ALC
# -------------
# Check for an ALC header, setting the variable fp_found_alc_header to no/yes,
# depending on the outcome.
AC_DEFUN([FP_HEADER_ALC],
[if test -z "$fp_found_alc_header"; then
  fp_found_alc_header=no
  AC_CHECK_HEADERS([AL/alc.h OpenAL/alc.h], [fp_found_alc_header=yes; break])
fi
]) # FP_HEADER_ALC


# FP_FUNC_ALCCLOSEDEVICE_VOID
# ---------------------------
# Defines ALCCLOSEDEVICE_VOID to 1 if `alcCloseDevice' returns void.
AC_DEFUN([FP_FUNC_ALCCLOSEDEVICE_VOID],
[AC_REQUIRE([FP_HEADER_ALC])
AC_CACHE_CHECK([whether alcCloseDevice returns void],
  [fp_cv_func_alcclosedevice_void],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([AC_INCLUDES_DEFAULT
#if defined(HAVE_AL_ALC_H)
#include <AL/alc.h>
#elif defined(HAVE_OPENAL_ALC_H)
#include <OpenAL/alc.h>
#endif
],
 [[int x = (int)alcCloseDevice(NULL);]])],
 [fp_cv_func_alcclosedevice_void=no],
 [fp_cv_func_alcclosedevice_void=yes])])
if test x"$fp_cv_func_alcclosedevice_void" = xyes; then
  AC_DEFINE([ALCCLOSEDEVICE_VOID], [1], [Define to 1 if `alcCloseDevice' returns void.])
fi
]) # FP_FUNC_ALCCLOSEDEVICE_VOID


# FP_FUNC_ALCMAKECONTEXTCURRENT_VOID
# ----------------------------------
# Defines ALCMAKECONTEXTCURRENT_VOID to 1 if `alcMakeContextCurrent' returns void.
AC_DEFUN([FP_FUNC_ALCMAKECONTEXTCURRENT_VOID],
[AC_REQUIRE([FP_HEADER_ALC])
AC_CACHE_CHECK([whether alcMakeContextCurrent returns void],
  [fp_cv_func_alcmakecontextcurrent_void],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([AC_INCLUDES_DEFAULT
#if defined(HAVE_AL_ALC_H)
#include <AL/alc.h>
#elif defined(HAVE_OPENAL_ALC_H)
#include <OpenAL/alc.h>
#endif
],
 [[int x = (int)alcMakeContextCurrent(NULL);]])],
 [fp_cv_func_alcmakecontextcurrent_void=no],
 [fp_cv_func_alcmakecontextcurrent_void=yes])])
if test x"$fp_cv_func_alcmakecontextcurrent_void)" = xyes; then
  AC_DEFINE([ALCMAKECONTEXTCURRENT_VOID], [1], [Define to 1 if `alcMakeContextCurrent' returns void.])
fi
]) # FP_FUNC_ALCMAKECONTEXTCURRENT_VOID


# FP_FUNC_ALCPROCESSCONTEXT_VOID
# ------------------------------
# Defines ALCPROCESSCONTEXT_VOID to 1 if `alcProcessContext' returns void.
AC_DEFUN([FP_FUNC_ALCPROCESSCONTEXT_VOID],
[AC_REQUIRE([FP_HEADER_ALC])
AC_CACHE_CHECK([whether alcProcessContext returns void],
  [fp_cv_func_alcprocesscontext_void],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([AC_INCLUDES_DEFAULT
#if defined(HAVE_AL_ALC_H)
#include <AL/alc.h>
#elif defined(HAVE_OPENAL_ALC_H)
#include <OpenAL/alc.h>
#endif
],
 [[int x = (int)alcProcessContext(NULL);]])],
 [fp_cv_func_alcprocesscontext_void=no],
 [fp_cv_func_alcprocesscontext_void=yes])])
if test x"$fp_cv_func_alcprocesscontext_void" = xyes; then
  AC_DEFINE([ALCPROCESSCONTEXT_VOID], [1], [Define to 1 if `alcProcessContext' returns void.])
fi
]) # FP_FUNC_ALCPROCESSCONTEXT_VOID


# FP_FUNC_ALCDESTROYCONTEXT_VOID
# ------------------------------
# Defines ALCDESTROYCONTEXT_VOID to 1 if `alcDestroyContext' returns void.
AC_DEFUN([FP_FUNC_ALCDESTROYCONTEXT_VOID],
[AC_REQUIRE([FP_HEADER_ALC])
AC_CACHE_CHECK([whether alcDestroyContext returns void],
  [fp_cv_func_alcdestroycontext_void],
  [AC_COMPILE_IFELSE([AC_LANG_PROGRAM([AC_INCLUDES_DEFAULT
#if defined(HAVE_AL_ALC_H)
#include <AL/alc.h>
#elif defined(HAVE_OPENAL_ALC_H)
#include <OpenAL/alc.h>
#endif
],
 [[int x = (int)alcDestroyContext(NULL);]])],
 [fp_cv_func_alcdestroycontext_void=no],
 [fp_cv_func_alcdestroycontext_void=yes])])
if test x"$fp_cv_func_alcdestroycontext_void" = xyes; then
  AC_DEFINE([ALCDESTROYCONTEXT_VOID], [1], [Define to 1 if `alcDestroyContext' returns void.])
fi
]) # FP_FUNC_ALCDESTROYCONTEXT_VOID


# FP_ARG_COMPILER
# -------------
AC_DEFUN([FP_ARG_COMPILER],
[AC_ARG_WITH([compiler],
  [AC_HELP_STRING([--with-compiler@<:@=HC@:>@],
    [use the given Haskell compiler (default=ghc)])],
  [with_compiler=$withval],
  [with_compiler=ghc])
])# FP_ARG_COMPILER
