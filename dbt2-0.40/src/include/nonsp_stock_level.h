/*
 * odbc_stock_level.h
 *
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2002 Mark Wong & Open Source Development Lab, Inc.
 *
 * 23 july 2002
 * Based on TPC-C Standard Specification Revision 5.0.
 */

#ifndef _NONSP_STOCK_LEVEL_H_
#define _NONSP_STOCK_LEVEL_H_

#include <transaction_data.h>
#include <nonsp_common.h>

int execute_stock_level(struct db_context_t *dbc, struct stock_level_t *data);
int stock_level(struct db_context_t *dbc, struct stock_level_t *data, char ** vals, int nvals);

#endif /* _NONSP_STOCK_LEVEL_H_ */
