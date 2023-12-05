/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef CREDITS_H
#  define CREDITS_H


#define CREDITS_MAX (((credits_t)1) << 53) /**< Maximum credits_t value that round-trips thru Lua. */
#define CREDITS_MIN (-CREDITS_MAX) /**< Minimum credits_t value that round-trips thru Lua. */
#define CREDITS_PRI PRIu64


typedef int64_t credits_t;


int credits2str(char *out, size_t maxlen, credits_t credits, int decimals);
int price2str(char *out, size_t maxlen, credits_t price, credits_t credits,
      int decimals);



#endif /* CREDITS_H */
