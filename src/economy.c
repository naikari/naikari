/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file economy.c
 *
 * @brief Handles economy stuff.
 *
 * Economy is handled with Nodal Analysis.  Systems are modelled as nodes,
 *  jump routes are resistances and production is modelled as node intensity.
 *  This is then solved with linear algebra after each time increment.
 */


/** @cond */
#include <stdint.h>
#include <stdio.h>

#if HAVE_SUITESPARSE_CS_H
#include <suitesparse/cs.h>
#else /* HAVE_SUITESPARSE_CS_H */
#include <cs.h>
#endif /* HAVE_SUITESPARSE_CS_H */

#include "naev.h"
/** @endcond */

#include "economy.h"

#include "array.h"
#include "credits.h"
#include "log.h"
#include "ndata.h"
#include "nstring.h"
#include "ntime.h"
#include "nxml.h"
#include "pilot.h"
#include "player.h"
#include "rng.h"
#include "space.h"
#include "spfx.h"


/*
 * Economy Nodal Analysis parameters.
 */
#define ECON_BASE_RES      30. /**< Base resistance value for any system. */
#define ECON_SELF_RES      3. /**< Additional resistance for the self node. */
#define ECON_FACTION_MOD   0.1 /**< Modifier on Base for faction standings. */
#define ECON_PROD_MODIFIER 500000. /**< Production modifier, divide production by this amount. */
#define ECON_PROD_VAR      0.01 /**< Defines the variability of production. */


/* systems stack. */
extern StarSystem *systems_stack; /**< Star system stack. */


/* @TODO get rid of these externs. */
extern Commodity* commodity_stack;


/*
 * Nodal analysis simulation for dynamic economies.
 */
static int econ_initialized = 0; /**< Is economy system initialized? */
static int econ_queued = 0; /**< Whether there are any queued updates. */
static cs *econ_G = NULL; /**< Admittance matrix. */
int *econ_comm = NULL; /**< Commodities to calculate. */



/**
 * @brief Gets the price of a good on a planet in a system.
 *
 *    @param com Commodity to get price of.
 *    @param sys System to get price of commodity.
 *    @param p Planet to get price of commodity.
 *    @return The price of the commodity.
 */
credits_t economy_getPrice( const Commodity *com,
      const StarSystem *sys, const Planet *p )
{
   /* Get current time in periods.
    */
   return economy_getPriceAtTime( com, sys, p, ntime_get());
}

/**
 * @brief Gets the price of a good on a planet in a system.
 *
 *    @param com Commodity to get price of.
 *    @param sys System to get price of commodity.
 *    @param p Planet to get price of commodity.
 *    @param tme Time to get price at, eg as retunred by ntime_get()
 *    @return The price of the commodity.
 */
credits_t economy_getPriceAtTime( const Commodity *com,
                                  const StarSystem *sys, const Planet *p, ntime_t tme )
{
   int i, k;
   double price;
   double t;
   CommodityPrice *commPrice;
   (void) sys;
   /* Get current time in periods.
    * Note, taking off and landing takes about 1e7 ntime, which is 1 period.
    * Time does not advance when on a planet.
    * Journey with a single jump takes approx 3e7, so about 3 periods.
    */
   t = ntime_convertSeconds(tme) / NT_HOUR_SECONDS;

   /* Get position in stack. */
   k = com - commodity_stack;

   /* Find what commodity that is. */
   for (i=0; i<array_size(econ_comm); i++)
      if (econ_comm[i] == k)
         break;

   /* Check if found. */
   if (i >= array_size(econ_comm)) {
      WARN(_("Price for commodity '%s' not known."), com->name);
      return 0;
   }

   /* and get the index on this planet */
   for ( i=0; i<array_size(p->commodities); i++) {
     if ( ( strcmp(p->commodities[i]->name, com->name) == 0 ) )
       break;
   }
   if (i >= array_size(p->commodities)) {
     WARN(_("Price for commodity '%s' not known on this planet."), com->name);
     return 0;
   }
   commPrice = &p->commodityPrice[i];
   /* Calculate price. */
   price = (commPrice->price + commPrice->sysVariation
            * sin(2 * M_PI * t / commPrice->sysPeriod)
         + commPrice->planetVariation
            * sin(2 * M_PI * t / commPrice->planetPeriod));
   return (credits_t) (price+0.5);/* +0.5 to round */
}

/**
 * @brief Gets the average price of a good on a planet.
 *
 *    @param com Commodity to get price of.
 *    @param p Planet to get price of commodity.
 *    @param[out] mean Sample mean, rounded to nearest credit.
 *    @param[out] std Sample standard deviation (via uncorrected population formula).
 *    @return 0 on success, 1 if the commodity is not available on the
 *       planet, or -1 if an error occurred.
 */
int economy_getAveragePlanetPrice( const Commodity *com, const Planet *p, credits_t *mean, double *std )
{
   int i,k;
   CommodityPrice *commPrice;
   /* Get position in stack */
   k = com - commodity_stack;

   /* Find what commodity this is */
   for ( i=0; i<array_size(econ_comm); i++ )
      if (econ_comm[i] == k)
         break;

   /* Check if found */
   if (i >= array_size(econ_comm)) {
      WARN(_("Average price for commodity '%s' not known."), com->name);
      *mean = 0;
      *std = 0;
      return -1;
   }

   /* and get the index on this planet */
   for (i=0; i<array_size(p->commodities); i++) {
     if ((strcmp(p->commodities[i]->name, com->name) == 0))
       break;
   }
   if (i >= array_size(p->commodities)) {
      *mean = 0;
      *std = 0;
      return 1;
   }

   commPrice = &p->commodityPrice[i];
   *mean = commPrice->price;
   *std = commPrice->sysVariation + commPrice->planetVariation;
   return 0;
}


/**
 * @brief Gets the average price of a good (anywhere).
 *
 *    @param com Commodity to get price of.
 *    @param[out] mean Sample mean, rounded to nearest credit.
 *    @param[out] std Sample standard deviation (via uncorrected population formula).
 *    @return 0 on success, 1 if no price info could be found for the
 *       commodity.
 */

int economy_getAveragePrice( const Commodity *com, credits_t *mean, double *std ) {
   int i, j;
   StarSystem *sys;
   Planet *p;
   credits_t pmean;
   double pstd;
   int mean_n = 0;
   credits_t mean_total = 0;
   credits_t price_min = -1;
   credits_t price_max = 0;

   for (i=0; i<array_size(systems_stack); i++) {
      sys = &systems_stack[i];
      for (j=0; j<array_size(sys->planets); j++) {
         p = sys->planets[j];
         if (planet_isKnown(p)
               && (economy_getAveragePlanetPrice(com, p, &pmean, &pstd) == 0)) {
            ++mean_n;
            mean_total += pmean;
            if (price_min < 0)
               price_min = pmean - pstd;
            else
               price_min = MIN(price_min, pmean - pstd);
            price_max = MAX(price_max, pmean + pstd);
         }
      }
   }

   if (mean_n <= 0) {
      *mean = 0;
      *std = 0;
      return 1;
   }

   *mean = mean_total / mean_n;
   *std = (double)MIN(*mean - price_min, price_max - *mean);

   return 0;
}


/**
 * @brief Initializes the economy.
 *
 *    @return 0 on success.
 */
int economy_init (void)
{
   int i;

   /* Must not be initialized. */
   if (econ_initialized)
      return 0;

   /* Allocate price space. */
   for (i=0; i<array_size(systems_stack); i++) {
      free(systems_stack[i].prices);
      systems_stack[i].prices = calloc(array_size(econ_comm), sizeof(double));
   }

   /* Mark economy as initialized. */
   econ_initialized = 1;

   /* Refresh economy. */
   economy_refresh();

   return 0;
}


/**
 * @brief Increments the queued update counter.
 *
 * @sa economy_execQueued
 */
void economy_addQueuedUpdate (void)
{
   econ_queued++;
}


/**
 * @brief Calls economy_refresh if an economy update is queued.
 */
int economy_execQueued (void)
{
   if (econ_queued)
      return economy_refresh();

   return 0;
}


/**
 * @brief Regenerates the economy matrix.  Should be used if the universe
 *  changes in any permanent way.
 */
int economy_refresh (void)
{
   /* Economy must be initialized. */
   if (econ_initialized == 0)
      return 0;

   /* Initialize the prices. */
   economy_update( 0 );

   return 0;
}


/**
 * @brief Updates the economy.
 *
 *    @param dt Deltatick in NTIME.
 */
int economy_update( unsigned int dt )
{
   (void)dt;
   econ_queued = 0;
   return 0;
}


/**
 * @brief Destroys the economy.
 */
void economy_destroy (void)
{
   int i;

   /* Must be initialized. */
   if (!econ_initialized)
      return;

   /* Clean up the prices in the systems stack. */
   for (i=0; i<array_size(systems_stack); i++) {
      free(systems_stack[i].prices);
      systems_stack[i].prices = NULL;
   }

   /* Destroy the economy matrix. */
   cs_spfree( econ_G );
   econ_G = NULL;

   /* Economy is now deinitialized. */
   econ_initialized = 0;
}

/**
 * @brief Used during startup to set price and variation of the economy, depending on planet information.
 *
 *    @param planet The planet to set price on.
 *    @param commodity The commodity to set the price of.
 *    @param commodityPrice Where to write the commodity price to.
 *    @return 0 on success.
 */
static int economy_calcPrice( Planet *planet, Commodity *commodity, CommodityPrice *commodityPrice ) {

   CommodityModifier *cm;
   double base, scale, factor;
   const char *factionname;

   /* Check the faction is not NULL.*/
   if (!faction_isFaction(planet->faction)) {
      WARN(_("Planet '%s' appears to have commodity '%s' defined, but no faction."), planet->name, commodity->name);
      return 1;
   }

   /* Reset price to the base commodity price. */
   commodityPrice->price = commodity->price;

   /* Get the cost modifier suitable for planet type/class. */
   cm = commodity->planet_modifier;
   scale = 1.;
   while ( cm != NULL ) {
      if ( ( strcmp( planet->class, cm->name ) == 0 ) ) {
         scale = cm->value;
         break;
      }
      cm = cm->next;
   }
   commodityPrice->price *= scale;
   commodityPrice->planetVariation = 0.5;
   commodityPrice->sysVariation = 0.;
   /* Use filename to specify a variation period. */
   base = 100;
   commodity->period = 32 * (planet->gfx_spaceName[strlen(PLANET_GFX_SPACE_PATH)] % 32) + planet->gfx_spaceName[strlen(PLANET_GFX_SPACE_PATH) + 1] % 32;
   commodityPrice->planetPeriod = commodity->period + base;

   /* Use filename of exterior graphic to modify the variation period.
      No rhyme or reason, just gives some variability. */
   scale = 1 + (strlen(planet->gfx_exterior) - strlen(PLANET_GFX_EXTERIOR_PATH) - 19) / 100.;
   commodityPrice->planetPeriod *= scale;

   /* Use population to modify price and variability.  The tanh function scales from -1 (small population)
      to +1 (large population), done on a log scale.  Price is then modified by this factor, scaled by a
      value defined in the xml, as is variation.  So for some commodities, prices increase with population,
      while for others, prices decrease. */
   factor = -1;
   if ( planet->population > 0 )
      factor = tanh( ( log((double)planet->population) - log(1e8) ) / 2 );
   base = commodity->population_modifier;
   commodityPrice->price *= 1 + factor * base;
   commodityPrice->planetVariation *= 0.5 - factor * 0.25;
   commodityPrice->planetPeriod *= 1 + factor * 0.5;

   /* Modify price based on faction (as defined in the xml).
      Some factions place a higher value on certain goods.
      Some factions are more stable than others.*/
   scale = 1.;
   cm = commodity->planet_modifier;

   factionname = faction_name(planet->faction);
   while ( cm != NULL ) {
      if ( strcmp( factionname, cm->name ) == 0 ) {
         scale = cm->value;
         break;
      }
      cm = cm->next;
   }
   commodityPrice->price *= scale;

   /* Range seems to go from 0-5, with median being 2.  Increased range
    * will increase safety and so lower prices and improve stability */
   commodityPrice->price *= (1 - planet->presenceRange/30.);
   commodityPrice->planetPeriod *= 1 / (1 - planet->presenceRange/30.);

   /* Make sure the price is always positive and non-zero */
   commodityPrice->price = MAX( commodityPrice->price, 1 );

   return 0;
}


/**
 * @brief Modifies commodity price based on system characteristics.
 *
 *    @param sys System.
 */
static void economy_modifySystemCommodityPrice(StarSystem *sys)
{
   int i,j,k;
   Planet *planet;
   CommodityPrice *avprice;

   avprice = array_create( CommodityPrice );
   for ( i=0; i<array_size(sys->planets); i++ ) {
      planet=sys->planets[i];
      for ( j=0; j<array_size(planet->commodityPrice); j++ ) {
        /* Largest is approx 35000.  Increased radius will increase price since further to travel,
           and also increase stability, since longer for prices to fluctuate, but by a larger amount when they do.*/
         planet->commodityPrice[j].price *= 1 + sys->radius/200000;
         planet->commodityPrice[j].planetPeriod *= 1 / (1 - sys->radius/200000.);
         planet->commodityPrice[j].planetVariation *= 1 / (1 - sys->radius/300000.);

         /* Increase price with volatility, which goes up to about 600.
            And with rdr_range_mod, since systems are harder to find. */
         planet->commodityPrice[j].price *= 1 + sys->nebu_volatility/6000.;
         planet->commodityPrice[j].price /= sys->rdr_range_mod;

         /* Use number of jumps to determine sytsem time period.  More jumps means more options for trade
            so shorter period.  Between 1 to 6 jumps.  Make the base time 1000.*/
         planet->commodityPrice[j].sysPeriod = 2000. / (array_size(sys->jumps) + 1);

         for ( k=0; k<array_size(avprice); k++) {
            if ( ( strcmp( planet->commodities[j]->name, avprice[k].name ) == 0 ) ) {
               avprice[k].updateTime++;
               avprice[k].price+=planet->commodityPrice[j].price;
               avprice[k].planetPeriod+=planet->commodityPrice[j].planetPeriod;
               avprice[k].sysPeriod+=planet->commodityPrice[j].sysPeriod;
               avprice[k].planetVariation+=planet->commodityPrice[j].planetVariation;
               avprice[k].sysVariation+=planet->commodityPrice[j].sysVariation;
               break;
            }
         }
         if ( k == array_size(avprice) ) {/* first visit of this commodity for this system */
            (void)array_grow( &avprice );
            avprice[k].name=planet->commodities[j]->name;
            avprice[k].updateTime=1;
            avprice[k].price=planet->commodityPrice[j].price;
            avprice[k].planetPeriod=planet->commodityPrice[j].planetPeriod;
            avprice[k].sysPeriod=planet->commodityPrice[j].sysPeriod;
            avprice[k].planetVariation=planet->commodityPrice[j].planetVariation;
            avprice[k].sysVariation=planet->commodityPrice[j].sysVariation;
         }
      }
   }
   /* Do some inter-planet averaging */
   for ( k=0; k<array_size(avprice); k++ ) {
      avprice[k].price/=avprice[k].updateTime;
      avprice[k].planetPeriod/=avprice[k].updateTime;
      avprice[k].sysPeriod/=avprice[k].updateTime;
      avprice[k].planetVariation/=avprice[k].updateTime;
      avprice[k].sysVariation/=avprice[k].updateTime;
   }
   /* And now apply the averaging */
   for ( i=0; i<array_size(sys->planets); i++ ) {
      planet=sys->planets[i];
      for ( j=0; j<array_size(planet->commodities); j++ ) {
         for ( k=0; k<array_size(avprice); k++ ) {
            if ( ( strcmp( planet->commodities[j]->name, avprice[k].name ) == 0 ) ) {
               planet->commodityPrice[j].price*=0.25;
               planet->commodityPrice[j].price+=0.75*avprice[k].price;
               planet->commodityPrice[j].sysVariation=0.2*avprice[k].planetVariation;
            }
         }
      }
   }
   array_shrink( &avprice );
   sys->averagePrice = avprice;
}


/**
 * @brief Calculates smoothing of commodity price based on neighbouring systems
 *
 *    @param sys System.
 */
static void economy_smoothCommodityPrice(StarSystem *sys)
{
   StarSystem *neighbour;
   CommodityPrice *avprice=sys->averagePrice;
   double price;
   int n,i,j,k;
   /*Now modify based on neighbouring systems */
   /*First, calculate mean price of neighbouring systems */

   for ( j =0; j<array_size(avprice); j++ ) {/* for each commodity in this system */
      price=0.;
      n=0;
      for ( i=0; i<array_size(sys->jumps); i++ ) {/* for each neighbouring system */
         neighbour=sys->jumps[i].target;
         for ( k=0; k<array_size(neighbour->averagePrice); k++ ) {
            if ( ( strcmp( neighbour->averagePrice[k].name, avprice[j].name ) == 0 ) ) {
               price+=neighbour->averagePrice[k].price;
               n++;
               break;
            }
         }
      }
      if (n!=0)
         avprice[j].sum=price/n;
      else
         avprice[j].sum=avprice[j].price;
   }
}

/**
 * @brief Modifies commodity price based on neighbouring systems
 *
 *    @param sys System.
 */
static void economy_calcUpdatedCommodityPrice(StarSystem *sys)
{
   CommodityPrice *avprice=sys->averagePrice;
   Planet *planet;
   int i,j,k;
   for ( j=0; j<array_size(avprice); j++ ) {
      /*Use mean price to adjust current price */
      avprice[j].price=0.5*(avprice[j].price + avprice[j].sum);
   }
   /*and finally modify assets based on the means */
   for ( i=0; i<array_size(sys->planets); i++ ) {
      planet=sys->planets[i];
      for ( j=0; j<array_size(planet->commodities); j++ ) {
         for ( k=0; k<array_size(avprice); k++ ) {
            if ( ( strcmp(avprice[k].name, planet->commodities[j]->name) == 0 ) ) {
               planet->commodityPrice[j].price = (
                     0.25*planet->commodityPrice[j].price
                        + 0.75*avprice[k].price );
               planet->commodityPrice[j].planetVariation = (
                     0.1 * (0.5*avprice[k].planetVariation
                           + 0.5*planet->commodityPrice[j].planetVariation) );
               planet->commodityPrice[j].planetVariation *= planet->commodityPrice[j].price;
               planet->commodityPrice[j].sysVariation *= planet->commodityPrice[j].price;
               break;
            }
         }
      }
   }
   array_free( sys->averagePrice );
   sys->averagePrice=NULL;
}

/**
 * @brief Initialises commodity prices for the sinusoidal economy model.
 *
 */
void economy_initialiseCommodityPrices(void)
{
   int i, j, k;
   Planet *planet;
   StarSystem *sys;
   Commodity *com;
   CommodityModifier *this, *next;
   /* First use planet attributes to set prices and variability */
   for (k=0; k<array_size(systems_stack); k++) {
      sys = &systems_stack[k];
      for ( j=0; j<array_size(sys->planets); j++ ) {
         planet = sys->planets[j];
         /* Set up the commodity prices on the system, based on its attributes. */
         for ( i=0; i<array_size(planet->commodities); i++ ) {
            if (economy_calcPrice(planet, planet->commodities[i], &planet->commodityPrice[i]))
               return;
         }
      }
   }

   /* Modify prices and availability based on system attributes, and do some inter-planet averaging to smooth prices */
   for ( i=0; i<array_size(systems_stack); i++ ) {
      sys = &systems_stack[i];
      economy_modifySystemCommodityPrice(sys);
   }

   /* Compute average prices for all systems */
   for ( i=0; i<array_size(systems_stack); i++ ) {
      sys = &systems_stack[i];
      economy_smoothCommodityPrice(sys);
   }

   /* Smooth prices based on neighbouring systems */
   for ( i=0; i<array_size(systems_stack); i++ ) {
      sys = &systems_stack[i];
      economy_calcUpdatedCommodityPrice(sys);
   }
   /* And now free temporary commodity information */
   for ( i=0 ; i<array_size(commodity_stack); i++ ) {
      com = &commodity_stack[i];
      next = com->planet_modifier;
      com->planet_modifier = NULL;
      while (next != NULL) {
         this = next;
         next = this->next;
         free(this->name);
         free(this);
      }
      next = com->faction_modifier;
      com->faction_modifier = NULL;
      while (next != NULL) {
         this = next;
         next = this->next;
         free(this->name);
         free(this);
      }
   }
}


/*
 * Calculates commodity prices for a single planet (e.g. as added by the unidiff), and does some smoothing over the system, but not neighbours.
 */
void economy_initialiseSingleSystem( StarSystem *sys, Planet *planet )
{
   int i;
   for ( i=0; i<array_size(planet->commodities); i++ ) {
      economy_calcPrice(planet, planet->commodities[i], &planet->commodityPrice[i]);
   }
   economy_modifySystemCommodityPrice(sys);
}
