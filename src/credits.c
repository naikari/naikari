/*
 * See Licensing and Copyright notice in naev.h
 */


/**
 * @file credits.c
 *
 * @brief Handles credits, the currency in Naikari.
 */


/** @cond */
#include <math.h>

#include "naev.h"
/** @endcond */

#include "credits.h"

#include "log.h"
#include "nstring.h"


/**
 * @brief Converts credits to a usable string for displaying.
 *
 *    @param[out] out Where to write the string.
 *    @param maxlen Maximum length of out string.
 *    @param credits Credits to display.
 *    @param decimals Decimals to use.
 *    @return Size of attempted string or negative if an error occurred.
 */
int credits2str(char *out, size_t maxlen, credits_t credits, int decimals)
{
   /* Some explanation is needed for the values we're checking, where
    * we're subtracting 5 times 10 raised to some power based on
    * decimals. The reason we're doing this is to avoid accurate
    * rounding up which would produce strings like "1000.00 M¢", where
    * "1.00 G¢" would have been more appropriate, because of e.g.
    * 999.999998 being accurately rounded up to 1000.00.
    *
    * Proper implementation of printf formatting is to use round half to
    * even, or bankers' rounding, which means that exactly 9.5 will
    * always round to 10. We can thus reduce the minimum number for each
    * category such that it is a series of 9s followed by one 5 and then
    * all zeroes. It turns out that this can be obtained with the simple
    * formula:
    *
    *    5 * 10^(n-decimals)
    *
    * …where "n" is the number of zeros in the normal minimum value
    * minus 2, so e.g. it's 1 for k¢ and 4 for M¢.
    *
    * Using this method eliminates the possibility of running into
    * values like "1000 M¢" while also, assuming the implementation is
    * good, not creating values like "0.99 G¢" (values like "0.99 G¢"
    * are still possible if the C library uses a different rounding
    * method, albeit only for one very specific value).
    */

   if (decimals < 0)
      return snprintf(out, maxlen, _("%.*f ¢"), 0, (double)credits);
   else if (credits >= 1000000000000000000LL - 5*(long long)pow(10, 16-decimals))
      return snprintf(out, maxlen, _("%.*f E¢"), decimals,
            (double)credits / 1000000000000000000.);
   else if (credits >= 1000000000000000LL - 5*(long long)pow(10, 13-decimals))
      return snprintf(out, maxlen, _("%.*f P¢"), decimals,
            (double)credits / 1000000000000000.);
   else if (credits >= 1000000000000LL - 5*(long long)pow(10, 10-decimals))
      return snprintf(out, maxlen, _("%.*f T¢"), decimals,
            (double)credits / 1000000000000.);
   else if (credits >= 1000000000L - 5*(long)pow(10, 7-decimals))
      return snprintf(out, maxlen, _("%.*f G¢"), decimals,
            (double)credits / 1000000000.);
   else if (credits >= 1000000 - 5*(int)pow(10, 4-decimals))
      return snprintf(out, maxlen, _("%.*f M¢"), decimals,
            (double)credits / 1000000.);
   else if (credits >= 1000 - 5*(int)pow(10, 1-decimals))
      return snprintf(out, maxlen, _("%.*f k¢"), decimals,
            (double)credits / 1000.);
   else
      return snprintf(out, maxlen, _("%.*f ¢"), decimals, (double)credits);
}


/**
 * @brief Like credits2str(), but hilights if too expensive.
 *
 *    @param[out] out Where to write the string.
 *    @param maxlen Maximum length of out string.
 *    @param price Price to display.
 *    @param credits Credits available.
 *    @param decimals Decimals to use.
 *    @return Size of attempted string or negative if an error occurred.
 */
int price2str(char *out, size_t maxlen, credits_t price, credits_t credits,
      int decimals)
{
   char *buf;
   int written;

   written = credits2str(out, maxlen, price, decimals);
   if (written < 0) {
      WARN("Error writing %f credits.", (double)price);
      return written;
   }
   else if (written >= (int)maxlen)
      WARN("Credits output was truncated: %s", out);

   if (price <= credits)
      return written;

   buf = strdup(out);
   written = snprintf(out, maxlen, "#X* %s#0", buf);
   free(buf);

   return written;
}
