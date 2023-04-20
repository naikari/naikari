/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file nstring.c
 *
 * @brief Some string routines for naev.
 */

/** @cond */
#include "naev.h"
/** @endcond */

#include "nstring.h"

#include "log.h"


/**
 * @brief A bounded version of strstr. Conforms to BSD semantics.
 *
 *    @param haystack The string to search in
 *    @param size The size of haystack
 *    @param needle The string to search for
 *    @return A pointer to the first occurrence of needle in haystack, or NULL
 */
#if !HAVE_STRNSTR
char *strnstr( const char *haystack, const char *needle, size_t size )
{
   size_t needlesize;
   const char *i, *j, *k, *end, *giveup;

   needlesize = strlen(needle);
   /* We can give up if needle is empty, or haystack can never contain it */
   if (needlesize == 0 || needlesize > size)
      return NULL;
   /* The pointer value that marks the end of haystack */
   end = haystack + size;
   /* The maximum value of i, because beyond this haystack cannot contain needle */
   giveup = end - needlesize + 1;

   /* i is used to iterate over haystack */
   for (i = haystack; i != giveup; i++) {
      /* j is used to iterate over part of haystack during comparison */
      /* k is used to iterate over needle during comparison */
      for (j = i, k = needle; j != end && *k != '\0'; j++, k++) {
         /* Bail on the first character that doesn't match */
         if (*j != *k)
            break;
      }
      /* If we've reached the end of needle, we've found a match */
      /* i contains the start of our match */
      if (*k == '\0')
         return (char*) i;
   }
   /* Fell through the loops, nothing found */
   return NULL;
}
#endif /* !HAVE_STRNSTR */


/**
 * @brief Finds a string inside another string case insensitively.
 *
 *    @param haystack String to look into.
 *    @param needle String to find.
 *    @return Pointer in haystack where needle was found or NULL if not found.
 */
#if !HAVE_STRCASESTR
char *strcasestr( const char *haystack, const char *needle )
{
   size_t hay_len, needle_len;

   /* Get lengths. */
   hay_len     = strlen(haystack);
   needle_len  = strlen(needle);

   /* Slow search. */
   while (hay_len >= needle_len) {
      if (strncasecmp(haystack, needle, needle_len) == 0)
         return (char*)haystack;

      haystack++;
      hay_len--;
   }

   return NULL;
}
#endif /* !HAVE_STRCASESTR */


/**
 * @brief Return a pointer to a new string, which is a duplicate of the string \p s
 *        (or, if necessary, which contains the first \p nn bytes of \p s plus a terminating null).
 *
 * Taken from glibc. Conforms to POSIX.1-2008.
 */
#if !HAVE_STRNDUP
char* strndup( const char *s, size_t n )
{
   size_t len = MIN( strlen(s), n );
   char *new = (char *) malloc (len + 1);
   if (new == NULL)
      return NULL;
   new[len] = '\0';
   return (char *) memcpy (new, s, len);
}
#endif /* !HAVE_STRNDUP */


/**
 * @brief Sort function for sorting strings with qsort().
 */
int strsort( const void *p1, const void *p2 )
{
   return strcmp(*(const char **) p1, *(const char **) p2);
}



/*
 * vasprintf() is taken from SDL. Original source:
 * https://github.com/libsdl-org/SDL/blob/0467301baf57389d96fafbe169fb07f4c10169bc/src/stdlib/SDL_string.c
 *
 * Modified slightly. License is as follows:
 *
 * Simple DirectMedia Layer
 * Copyright (C) 1997-2023 Sam Lantinga <slouken@libsdl.org>
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */
/**
 * @brief vasprintf implementation.
 *
 *    @param[out] strp Used to return the allocated char* in case of success. Caller must free.
 *    @param fmt Same as vsprintf().
 *    @param ap Same as vsprintf().
 *    @return -1 if it failed, otherwise the number of bytes "printed".
 */
#if !HAVE_VASPRINTF
int vasprintf( char** strp, const char* fmt, va_list ap )
{
    int retval;
    int size = 100; /* Guess we need no more than 100 bytes */
    char *p, *np;
    va_list aq;

    *strp = NULL;

    p = malloc(size);
    if (p == NULL) {
        return -1;
    }

    while (1) {
        /* Try to print in the allocated space */
        va_copy(aq, ap);
        retval = vsnprintf(p, size, fmt, aq);
        va_end(aq);

        /* Check error code */
        if (retval < 0) {
            return retval;
        }

        /* If that worked, return the string */
        if (retval < size) {
            *strp = p;
            return retval;
        }

        /* Else try again with more space */
        size = retval + 1; /* Precisely what is needed */

        np = realloc(p, size);
        if (np == NULL) {
            free(p);
            return -1;
        } else {
            p = np;
        }
    }
}
#endif /* !HAVE_VASPRINTF */


/**
 * @brief Like sprintf(), but it allocates a large-enough string and returns the pointer in the first argument.
 *        Conforms to GNU and BSD libc semantics.
 *
 * @param[out] strp Used to return the allocated char* in case of success. Caller must free.
 *                  In case of failure, *strp is set to NULL, but don't rely on this because the GNU version doesn't guarantee it.
 * @param fmt Same as sprintf().
 * @return -1 if it failed, otherwise the number of bytes "printed".
 */
#if !HAVE_ASPRINTF
int asprintf( char** strp, const char* fmt, ... )
{
   int n;
   va_list ap;

   va_start( ap, fmt );
   n = vasprintf( strp, fmt, ap );
   va_end( ap );
   return n;
}
#endif /* !HAVE_ASPRINTF */


/**
 * @brief Like snprintf(), but returns the number of characters \em ACTUALLY "printed" into the buffer.
 *        This makes it possible to chain these calls to concatenate into a buffer without introducing a potential bug every time.
 *        This call was first added to the Linux kernel by Juergen Quade.
 */
int scnprintf( char* text, size_t maxlen, const char* fmt, ... )
{
   int n;
   va_list ap;

   if (!maxlen)
      return 0;

   va_start( ap, fmt );
   n = vsnprintf( text, maxlen, fmt, ap );
   va_end( ap );
   return MIN( maxlen-1, (size_t)n );
}


/**
 * @brief Creates a variant of a string which is safe for file names.
 *
 *    @param out Where to write the converted string.
 *    @param maxlen Maximum length of out string.
 *    @param s The string to convert.
 *    @return Number of characters written.
 */
size_t str2filename(char *out, size_t maxlen, const char *s)
{
   int i;
   size_t l = 0;

   if ((s == NULL) || (out == NULL))
      return 0;

   /* Illegal characters on Linux FS:
    *    ':'
    *    0
    * Illegal characters on Windows FS:
    *    '<' '>' ':' '"' '/' '\\' '|' '?' '*'
    *    0-31
    * Potentially problematic characters:
    *    '.'
    *    Unicode characters
    * Reserved Windows names:
    *    'CON' 'PRN' 'AUX' 'NUL' 'COM1'…'COM9' 'LPT1'…'LPT9'
    * '!' is also converted since it's used in replacement notation. */
   for (i=0; s[i]!='\0'; i++) {
      if ((s[i] <= 31) || (s[i] >= 127)) {
         l += scnprintf(&out[l], maxlen - l, "!%02x", (unsigned int)s[i]);
         continue;
      }

      switch (s[i]) {
         case ':':
         case '<':
         case '>':
         case '"':
         case '\\':
         case '/':
         case '|':
         case '?':
         case '*':
         case '.':
         case '!':
            l += scnprintf(&out[l], maxlen - l, "!%02x", (unsigned int)s[i]);
            break;

         default:
            l += scnprintf(&out[l], maxlen - l, "%c", s[i]);
      }
   }
#if defined(_WIN32) || defined(__CYGWIN__)
   /* Extra protections just for Windows. Keeping it out of Linux
    * because this reserved names thing is rather silly. */
   if ((strcasestr(out, "con") != NULL)
         || (strcasestr(out, "prn") != NULL)
         || (strcasestr(out, "aux") != NULL)
         || (strcasestr(out, "nul") != NULL)
         || (strcasestr(out, "com") != NULL)
         || (strcasestr(out, "lpt") != NULL))
      l += scnprintf(&out[l], maxlen - l, "%s", "!X");
#endif

   return l;
}
