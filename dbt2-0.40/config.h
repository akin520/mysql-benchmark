/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.ac by autoheader.  */


#ifndef __CONFIG_H__
#define __CONFIG_H__


/* Pthread semaphores are broken */
#define BROKEN_SEMAPHORES 1

/* Build for DARWIN */
/* #undef DARWIN */

/* Define to 1 if you don't have `vprintf' but do have `_doprnt.' */
/* #undef HAVE_DOPRNT */

/* Define to 1 if you have the `gettimeofday' function. */
#define HAVE_GETTIMEOFDAY 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <isqlext.h> header file. */
/* #undef HAVE_ISQLEXT_H */

/* Define to 1 if you have the <isqltypes.h> header file. */
/* #undef HAVE_ISQLTYPES_H */

/* Define to 1 if you have the <isql.h> header file. */
/* #undef HAVE_ISQL_H */

/* Define to 1 if you have the `c_r' library (-lc_r). */
/* #undef HAVE_LIBC_R */

/* Define to 1 if you have the `m' library (-lm). */
#define HAVE_LIBM 1

/* Define to 1 if you have the `posix4' library (-lposix4). */
/* #undef HAVE_LIBPOSIX4 */

/* Define to 1 if you have the `pthread' library (-lpthread). */
#define HAVE_LIBPTHREAD 1

/* Define to 1 if you have the `pthreads' library (-lpthreads). */
/* #undef HAVE_LIBPTHREADS */

/* Define to 1 if you have the `z' library (-lz). */
/* #undef HAVE_LIBZ */

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if PostgreSQL libraries are available */
/* #undef HAVE_POSTGRESQL */

/* Define to 1 if you have the `socket' function. */
#define HAVE_SOCKET 1

/* Define to 1 if you have the <sqlext.h> header file. */
/* #undef HAVE_SQLEXT_H */

/* Define to 1 if you have the <sqltypes.h> header file. */
/* #undef HAVE_SQLTYPES_H */

/* Define to 1 if you have the <sql.h> header file. */
/* #undef HAVE_SQL_H */

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1

/* Define to 1 if you have the `vprintf' function. */
#define HAVE_VPRINTF 1

/* using MySQL */
#define LIBMYSQL 1

/* using PostgreSQL */
/* #undef LIBPQ */

/* Build for Linux */
#define LINUX 1

/* SP based version of test */
/* #undef MYSQL_SP */

/* using ODBC to SAPDB */
/* #undef ODBC */

/* Name of package */
#define PACKAGE "dbt2"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT "osdldbt-general@lists.sourceforge.net"

/* Define to the full name of this package. */
#define PACKAGE_NAME "dbt2"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "dbt2 0.40"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "dbt2"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.40"

/* Build for solaris */
/* #undef SOLARIS */

/* Define to 1 if you have the ANSI C header files. */
#define STDC_HEADERS 1

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. */
#define TIME_WITH_SYS_TIME 1

/* Define to 1 if your <sys/time.h> declares `struct tm'. */
/* #undef TM_IN_SYS_TIME */

/* Version number of package */
#define VERSION "0.40"

/* Number of bits in a file offset, on hosts where this is settable. */
/* #undef _FILE_OFFSET_BITS */

/* Define for large files, on AIX-style hosts. */
/* #undef _LARGE_FILES */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef const */


#endif

