/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2002 Mark Wong & Open Source Development Labs, Inc.
 * Copyright (C) 2004 Alexey Stroganov & MySQL AB.
 *
 */


#include "nonsp_stock_level.h"

int execute_stock_level(struct db_context_t *dbc, struct stock_level_t *data)
{
        int rc;
        char *  vals[2];
        int nvals=2;

        rc=stock_level(dbc, data, vals, nvals);

        if (rc == -1 )
        {
          LOG_ERROR_MESSAGE("STOCK LEVEL FINISHED WITH ERRORS \n");

          //should free memory that was allocated for nvals vars
          dbt2_free_values(vals, nvals);

          return ERROR;
        }

        return OK;
}


int stock_level(struct db_context_t *dbc, struct stock_level_t *data, char ** vals, int nvals)
{
	/* Input variables. */
	int w_id = data->w_id;
	int d_id = data->d_id;
	int threshold = data->threshold;

        struct sql_result_t result;

	int d_next_o_id = 0;
	int low_stock = 0;
	char query[256];

        int D_NEXT_O_ID=0;
        int LOW_STOCK=1;
 
        dbt2_init_values(vals, nvals);

	sprintf(query, STOCK_LEVEL_1, w_id, d_id);

#ifdef DEBUG_QUERY
        LOG_ERROR_MESSAGE("STOCK_LEVEL_1 query: %s\n",query);
#endif
        if (dbt2_sql_execute(dbc, query, &result, "STOCK_LEVEL_1") && result.result_set)
        {
          dbt2_sql_fetchrow(dbc, &result);
          vals[D_NEXT_O_ID] = dbt2_sql_getvalue(dbc, &result, 0); //D_NEXT_O_ID
          dbt2_sql_close_cursor(dbc, &result);

          if (!vals[D_NEXT_O_ID])
          {
            LOG_ERROR_MESSAGE("ERROR: D_NEXT_O_ID=NULL for query STOCK_LEVEL_1:\n%s\n", query);
            return -1;
          }
          d_next_o_id = atoi(vals[D_NEXT_O_ID]);
        }
        else //error
        {
          return -1;
        }

	sprintf(query, STOCK_LEVEL_2, d_id, w_id, threshold, d_next_o_id - 20,
		d_next_o_id - 1);

#ifdef DEBUG_QUERY
        LOG_ERROR_MESSAGE("STOCK_LEVEL_2 query: %s\n",query);
#endif
        if (dbt2_sql_execute(dbc, query, &result, "STOCK_LEVEL_2") && result.result_set)
        {
          dbt2_sql_fetchrow(dbc, &result);

          vals[LOW_STOCK]= dbt2_sql_getvalue(dbc, &result, 0); //LOW_STOCK
          dbt2_sql_close_cursor(dbc, &result);

          if (!vals[LOW_STOCK])
          {
            LOG_ERROR_MESSAGE("ERROR: LOW_STOCK=NULL for query STOCK_LEVEL_2:\n%s\n", query);
            return -1;
          }
          low_stock = atoi(vals[LOW_STOCK]);
        }
        else //error
        {
          return -1;
        }

        dbt2_free_values(vals, nvals);

        return 1;
}

