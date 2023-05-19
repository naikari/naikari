/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file land_trade.c
 *
 * @brief Handles the Trading Center at land.
 */


/** @cond */
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "land_trade.h"

#include "array.h"
#include "commodity.h"
#include "dialogue.h"
#include "economy.h"
#include "hook.h"
#include "land.h"
#include "land_shipyard.h"
#include "log.h"
#include "map_find.h"
#include "ndata.h"
#include "nstring.h"
#include "player.h"
#include "space.h"
#include "tk/toolkit_priv.h"
#include "toolkit.h"


static int commodity_mod = 10;
static iar_data_t *iar_data = NULL; /**< Stored image array positions. */


static void commodity_getSize(unsigned int wid, int *w, int *h,
      int *iw, int *ih, int *dw, int *bw);
static void commodity_genList(unsigned int wid);


/**
 * @brief Gets the size of the commodities window.
 */
static void commodity_getSize(unsigned int wid, int *w, int *h,
      int *iw, int *ih, int *dw, int *bw)
{
   /* Get window dimensions. */
   window_dimWindow(wid, w, h);

   /* Calculate image array dimensions. */
   /* Window size minus right column size minus space on left and right */
   if (iw != NULL)
      *iw = 565 + (*w - LAND_WIDTH);
   if (ih != NULL)
      *ih = *h - 60;

   if (dw != NULL)
      *dw = *w - (iw!=NULL?*iw:0) - 60;

   if (bw != NULL)
      *bw = ((dw != NULL ? *dw+20 : *w) - 2*10) / 3;
}


/**
 * @brief Opens the local market window.
 */
void commodity_exchange_open( unsigned int wid )
{
   int w, h, iw, ih, dw, bw, titleHeight, infoHeight;
   const char *bufSInfo;

   /* Mark as generated. */
   land_tabGenerate(LAND_WINDOW_COMMODITY);

   commodity_getSize(wid, &w, &h, &iw, &ih, &dw, &bw);

   /* Initialize stored positions. */
   if (iar_data == NULL)
      iar_data = calloc(1, sizeof(iar_data_t));
   else
      memset(iar_data, 0, sizeof(iar_data_t));

   /* buttons */
   window_addButtonKey(wid, -10, 20, bw, LAND_BUTTON_HEIGHT,
         "btnCommodityClose", _("&Take Off"), land_buttonTakeoff, SDLK_t);
   window_addButtonKey(wid, -10 - 1*(bw+10), 20, bw, LAND_BUTTON_HEIGHT,
         "btnCommoditySell", _("&Sell"), commodity_sell, SDLK_s);
   window_addButtonKey(wid, -10 - 2*(bw+10), 20, bw, LAND_BUTTON_HEIGHT,
         "btnCommodityBuy", _("&Buy"), commodity_buy, SDLK_b);

      /* cust draws the modifier : # of tons one click buys or sells */
   window_addCust( wid, 40 + iw, 40 + LAND_BUTTON_HEIGHT, 2*bw + 20,
         gl_smallFont.h + 6, "cstMod", 0, commodity_renderMod, NULL, NULL );

   /* store gfx */
   window_addRect( wid, -20, -40, 192, 192, "rctStore", &cBlack, 0 );
   window_addImage( wid, -20, -40, 192, 192, "imgStore", NULL, 1 );

   /* text */
   titleHeight = gl_printHeightRaw(&gl_defFont, LAND_BUTTON_WIDTH+80, _("None"));
   window_addText( wid, 40 + iw, -40, dw, titleHeight, 0,
         "txtName", &gl_defFont, NULL, _("None") );

   bufSInfo = _(
           "#nYou have:#0\n"
           "#nPurchased for:#0\n"
           "#nMarket Price:#0\n"
           "\n"
           "#nAverage price here:#0\n"
           "#nAverage price all:#0\n"
           "\n"
           "#nFree Space:#0\n"
           "#nMoney:#0");
   infoHeight = gl_printHeightRaw(&gl_defFont, dw - (20+192), bufSInfo);

   window_addText( wid, 40 + iw, -60 - titleHeight, dw - (20+192), infoHeight,
         0, "txtDInfo", &gl_defFont, NULL, NULL );

   window_addText( wid, 40 + iw, MIN(-60-titleHeight-infoHeight-40, -192-60),
         dw, h - (80+titleHeight+infoHeight) - (40+LAND_BUTTON_HEIGHT), 0,
         "txtDesc", &gl_smallFont, NULL, NULL );

   commodity_genList(wid);

   /* Set default keyboard focuse to the list */
   window_setFocus( wid , "iarTrade" );
}


/**
 * @brief Regenerates the commodities list.
 *
 *    @param wid Window to generate the list on.
 */
void commodity_regenList(unsigned int wid)
{
   char *focused;

   /* Save focus. */
   focused = window_getFocus(wid);

   /* Save positions. */
   toolkit_saveImageArrayData(wid, "iarTrade", iar_data);

   /* Destroy and recreate. */
   window_destroyWidget(wid, "iarTrade");
   commodity_genList(wid);

   /* Restore positions. */
   toolkit_setImageArrayPos(wid, "iarTrade", iar_data->pos);
   toolkit_setImageArrayOffset(wid, "iarTrade", iar_data->offset);

   commodity_update(wid, NULL);

   /* Restore focus. */
   window_setFocus(wid, focused);
   free(focused);
}


/**
 * @brief Generates the commodities list.
 *
 *    @param wid Window to generate the list on.
 */
static void commodity_genList(unsigned int wid)
{
   int i, ngoods;
   ImageArrayCell *cgoods;
   int w, h, iw, ih;
   int iconsize;

   commodity_getSize(wid, &w, &h, &iw, &ih, NULL, NULL);

   if (array_size(land_planet->commodities) > 0) {
      ngoods = array_size(land_planet->commodities);
      cgoods = calloc(ngoods, sizeof(ImageArrayCell));
      for (i=0; i<ngoods; i++) {
         cgoods[i].image = gl_dupTexture(land_planet->commodities[i]->gfx_store);
         cgoods[i].caption = strdup(_(land_planet->commodities[i]->name));
         cgoods[i].quantity = pilot_cargoOwned(player.p,
               land_planet->commodities[i]);
      }
   }
   else {
      ngoods = 1;
      cgoods = calloc(ngoods, sizeof(ImageArrayCell));
      cgoods[0].image = NULL;
      cgoods[0].caption = strdup(_("None"));
   }

   /* set up the goods to buy/sell */
   iconsize = 128;
   window_addImageArray(wid, 20, 20,
         iw, ih, "iarTrade", iconsize, iconsize,
         cgoods, ngoods, commodity_update, commodity_update, commodity_update);

   commodity_update(wid, NULL);
}


/**
 * @brief Updates the commodity window.
 *    @param wid Window to update.
 *    @param str Unused.
 */
void commodity_update( unsigned int wid, char* str )
{
   (void)str;
   char buf[PATH_MAX];
   char buf_purchase_price[ECON_CRED_STRLEN], buf_credits[ECON_CRED_STRLEN];
   int i;
   Commodity *com;
   credits_t mean,globalmean;
   double std, globalstd;
   char buf_mean[ECON_CRED_STRLEN], buf_globalmean[ECON_CRED_STRLEN];
   char buf_std[ECON_CRED_STRLEN], buf_globalstd[ECON_CRED_STRLEN];
   char buf_local_price[ECON_CRED_STRLEN];
   char buf_tonnes_owned[ECON_MASS_STRLEN], buf_tonnes_free[ECON_MASS_STRLEN];
   int owned;
   i = toolkit_getImageArrayPos( wid, "iarTrade" );
   if (i < 0 || array_size(land_planet->commodities) == 0) {
      credits2str( buf_credits, player.p->credits, 2 );
      tonnes2str( buf_tonnes_free, pilot_cargoFree(player.p) );
      snprintf(buf, PATH_MAX,
         _("#nYou have:#0 N/A\n"
            "#nPurchased for:#0 N/A\n"
            "#nMarket Price:#0 N/A\n"
            "\n"
            "#nAverage price here:#0 N/A\n"
            "#nAverage price all:#0 N/A\n"
            "\n"
            "#nFree Space:#0 %s\n"
            "#nMoney:#0 %s"),
         buf_tonnes_free, buf_credits);
      window_modifyText( wid, "txtDInfo", buf );
      window_modifyText( wid, "txtDesc", _("No commodities available.") );
      window_disableButton( wid, "btnCommodityBuy" );
      window_disableButton( wid, "btnCommoditySell" );
      return;
   }
   com = land_planet->commodities[i];

   /* modify image */
   window_modifyImage( wid, "imgStore", com->gfx_store, 192, 192 );

   planet_averagePlanetPrice( land_planet, com, &mean, &std);
   credits2str( buf_mean, mean, -1 );
   /* TODO credit2str could learn to do this... */
   snprintf(buf_std, sizeof(buf_std), _("%.1f ¢"), std);
   economy_getAveragePrice( com, &globalmean, &globalstd );
   credits2str( buf_globalmean, globalmean, -1 );
   /* TODO credit2str could learn to do this... */
   snprintf(buf_globalstd, sizeof(buf_globalstd), _("%.1f ¢"), globalstd);
   /* modify text */
   strcpy(buf_purchase_price, _("N/A"));
   owned = pilot_cargoOwned(player.p, com);
   if (owned > 0)
      credits2str(buf_purchase_price, com->lastPurchasePrice, -1);
   credits2str(buf_credits, player.p->credits, 2);
   credits2str(buf_local_price, planet_commodityPrice(land_planet, com), -1);
   tonnes2str(buf_tonnes_owned, owned);
   tonnes2str(buf_tonnes_free, pilot_cargoFree(player.p));
   snprintf(buf, sizeof(buf),
              _("#nYou have:#0 %s\n"
                 "#nPurchased for:#0 %s\n"
                 "#nMarket Price:#0 %s/kt\n"
                 "\n"
                 "#nAverage price here:#0 %s/kt ± %s/kt\n"
                 "#nAverage price all:#0 %s/kt ± %s/kt\n"
                 "\n"
                 "#nFree Space:#0 %s\n"
                 "#nMoney:#0 %s"),
              buf_tonnes_owned, buf_purchase_price, buf_local_price,
              buf_mean, buf_std,
              buf_globalmean, buf_globalstd,
              buf_tonnes_free, buf_credits);

   window_modifyText( wid, "txtDInfo", buf );
   window_modifyText( wid, "txtName", _(com->name) );
   window_modifyText( wid, "txtDesc", _(com->description) );

   /* Button enabling/disabling */
   if (commodity_canBuy( com ))
      window_enableButton( wid, "btnCommodityBuy" );
   else
      window_disableButtonSoft( wid, "btnCommodityBuy" );

   if (commodity_canSell( com ))
      window_enableButton( wid, "btnCommoditySell" );
   else
      window_disableButtonSoft( wid, "btnCommoditySell" );
}


/**
 * @brief Updates the outfitter and equipment outfit image arrays.
 */
void commodity_updateOwnedCargo(void)
{
   int w;

   if (!landed || !land_doneLoading())
      return;

   if (!planet_hasService(land_planet, PLANET_SERVICE_COMMODITY))
      return;

   w = land_getWid(LAND_WINDOW_COMMODITY);
   commodity_regenList(w);
}


int commodity_canBuy( const Commodity* com )
{
   int failure;
   unsigned int q, price;
   char buf[ECON_CRED_STRLEN];

   failure = 0;
   q = commodity_getMod();
   price = planet_commodityPrice( land_planet, com ) * q;

   if (!player_hasCredits( price )) {
      credits2str( buf, price - player.p->credits, 2 );
      land_errDialogueBuild(_("You need %s more."), buf );
      failure = 1;
   }
   if (pilot_cargoFree(player.p) <= 0) {
      land_errDialogueBuild(_("No cargo space available!"));
      failure = 1;
   }

   return !failure;
}


int commodity_canSell( const Commodity* com )
{
   int failure;

   failure = 0;

   if (pilot_cargoOwned( player.p, com ) == 0) {
      land_errDialogueBuild(_("You can't sell something you don't have!"));
      failure = 1;
   }

   return !failure;
}


/**
 * @brief Buys the selected commodity.
 *    @param wid Window buying from.
 *    @param str Unused.
 */
void commodity_buy( unsigned int wid, char* str )
{
   (void)str;
   int i;
   Commodity *com;
   unsigned int q;
   credits_t price;
   HookParam hparam[3];

   /* Get selected. */
   q     = commodity_getMod();
   i     = toolkit_getImageArrayPos( wid, "iarTrade" );
   com   = land_planet->commodities[i];
   price = planet_commodityPrice( land_planet, com );

   /* Check stuff. */
   if (land_errDialogue( com->name, "buyCommodity" ))
      return;

   /* Make the buy. */
   q = pilot_cargoAdd( player.p, com, q, 0 );
   com->lastPurchasePrice = price; /* To show the player how much they paid for it */
   price *= q;
   player_modCredits( -price );

   /* Run hooks. */
   hparam[0].type = HOOK_PARAM_STRING;
   hparam[0].u.str= com->name;
   hparam[1].type = HOOK_PARAM_NUMBER;
   hparam[1].u.num = q;
   hparam[2].type = HOOK_PARAM_SENTINEL;
   hooks_runParam("comm_buy", hparam);
   if (land_takeoff)
      takeoff(1);

   /* Regenerate list. */
   commodity_regenList(wid);
}
/**
 * @brief Attempts to sell a commodity.
 *    @param wid Window selling commodity from.
 *    @param str Unused.
 */
void commodity_sell( unsigned int wid, char* str )
{
   (void)str;
   int i;
   Commodity *com;
   unsigned int q;
   credits_t price;
   HookParam hparam[3];

   /* Get parameters. */
   q     = commodity_getMod();
   i     = toolkit_getImageArrayPos( wid, "iarTrade" );
   com   = land_planet->commodities[i];
   price = planet_commodityPrice( land_planet, com );

   /* Check stuff. */
   if (land_errDialogue( com->name, "sellCommodity" ))
      return;

   /* Remove commodity. */
   q = pilot_cargoRm( player.p, com, q );
   price = price * (credits_t)q;
   player_modCredits( price );
   if ( pilot_cargoOwned( player.p, com ) == 0 ) /* None left, set purchase price to zero, in case missions add cargo. */
     com->lastPurchasePrice = 0;

   /* Run hooks. */
   hparam[0].type = HOOK_PARAM_STRING;
   hparam[0].u.str = com->name;
   hparam[1].type = HOOK_PARAM_NUMBER;
   hparam[1].u.num = q;
   hparam[2].type = HOOK_PARAM_SENTINEL;
   hooks_runParam("comm_sell", hparam);
   if (land_takeoff)
      takeoff(1);

   /* Regenerate list. */
   commodity_regenList(wid);
}

/**
 * @brief Gets the current modifier status.
 *    @return The amount modifier when buying or selling commodities.
 */
int commodity_getMod (void)
{
   SDL_Keymod mods;
   int q;

   mods = SDL_GetModState();
   q = 10;
   if (mods & (KMOD_LCTRL | KMOD_RCTRL))
      q *= 5;
   if (mods & (KMOD_LSHIFT | KMOD_RSHIFT))
      q *= 10;

   return q;
}
/**
 * @brief Renders the commodity buying modifier.
 *    @param bx Base X position to render at.
 *    @param by Base Y position to render at.
 *    @param w Width to render at.
 *    @param h Height to render at.
 *    @param data Unused.
 */
void commodity_renderMod( double bx, double by, double w, double h, void *data )
{
   (void) data;
   (void) h;
   int q;
   char buf[8];

   q = commodity_getMod();
   if (q != commodity_mod) {
      commodity_update( land_getWid(LAND_WINDOW_COMMODITY), NULL );
      commodity_mod = q;
   }
   snprintf( buf, 8, "%d×", q );
   gl_printMidRaw( &gl_smallFont, w, bx, by, &cFontWhite, -1, buf );
}
