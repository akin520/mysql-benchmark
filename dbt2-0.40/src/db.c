/*
 * This file is released under the terms of the Artistic License.  Please see
 * the file LICENSE, included in this package, for details.
 *
 * Copyright (C) 2002 Mark Wong & Open Source Development Labs, Inc.
 *
 * 16 June 2002
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "db.h"
#include "logging.h"

#ifdef ODBC
#include "odbc_delivery.h"
#include "odbc_order_status.h"
#include "odbc_payment.h"
#include "odbc_stock_level.h"
#include "odbc_new_order.h"
#include "odbc_integrity.h"
#endif /* ODBC */

#ifdef LIBPQ
#include "libpq_delivery.h"
#include "libpq_order_status.h"
#include "libpq_payment.h"
#include "libpq_stock_level.h"
#include "libpq_new_order.h"
#include "libpq_integrity.h"
#endif /* LIBPQ */


#ifdef LIBMYSQL
#include "mysql_delivery.h"
#include "mysql_order_status.h"
#include "mysql_payment.h"
#include "mysql_stock_level.h"
#include "mysql_new_order.h"
#include "mysql_integrity.h"
#endif /* LIBMYSQL */


int connect_to_db(struct db_context_t *dbc) {
	int rc;

	rc = _connect_to_db(dbc);
	if (rc != OK) {
		return ERROR;
	}

	return OK;
}

#ifdef ODBC
int db_init(char *sname, char *uname, char *auth)
#endif /* ODBC */
#ifdef LIBPQ
int db_init(char *_dbname, char *_pghost, char *_pgport)
#endif /* LIBPQ */
#ifdef LIBMYSQL
int db_init(char * _mysql_dbname, char *_mysql_host, char * _mysql_user,
             char * _mysql_pass, char * _mysql_port, char * _mysql_socket)
#endif /* LIBMYSQL */

{
	int rc;

#ifdef ODBC
	rc = _db_init(sname, uname, auth);
#endif /* ODBC */

#ifdef LIBPQ
	rc = _db_init(_dbname, _pghost, _pgport);
#endif /* LIBPQ */

#ifdef LIBMYSQL
        rc = _db_init(_mysql_dbname, _mysql_host, _mysql_user, _mysql_pass, 
                      _mysql_port, _mysql_socket);
#endif /* LIBMYSQL */


	return OK;
}

int disconnect_from_db(struct db_context_t *dbc) {
	int rc;

#ifdef ODBC
	/* ODBC _disconnect_from_db() is halting for some reason. */
	return OK;
#endif /* ODBC */
	rc = _disconnect_from_db(dbc);
	if (rc != OK) {
		return ERROR;
	}

	return OK;
}

int process_transaction(int transaction, struct db_context_t *dbc,
	union transaction_data_t *td)
{
	int rc;
	int i;
	int status;

	switch (transaction) {
	case INTEGRITY:
		rc = execute_integrity(dbc, &td->integrity);
		break;
	case DELIVERY:
		rc = execute_delivery(dbc, &td->delivery);
		break;
	case NEW_ORDER:
		td->new_order.o_all_local = 1;
		for (i = 0; i < td->new_order.o_ol_cnt; i++) {
			if (td->new_order.order_line[i].ol_supply_w_id !=
					td->new_order.w_id) {
				td->new_order.o_all_local = 0;
				break;
			}
		}
		rc = execute_new_order(dbc, &td->new_order);
		if (rc != ERROR && td->new_order.rollback == 0) {
			/*
			 * Calculate the adjusted total_amount here to work
			 * around an issue with SAP DB stored procedures that
			 * does not allow any statements to execute after a
			 * SUBTRANS ROLLBACK without throwing an error.
	 		 */
			td->new_order.total_amount =
				td->new_order.total_amount *
				(1 - td->new_order.c_discount) *
				(1 + td->new_order.w_tax + td->new_order.d_tax);
		} else {
			rc = ERROR;
		}
		break;
	case ORDER_STATUS:
		rc = execute_order_status(dbc, &td->order_status);
		break;
	case PAYMENT:
		rc = execute_payment(dbc, &td->payment);
		break;
	case STOCK_LEVEL:
		rc = execute_stock_level(dbc, &td->stock_level);
		break;
	default:
		LOG_ERROR_MESSAGE("unknown transaction type %d", transaction);
		return ERROR;
	}

	/* Commit or rollback the transaction. */
	if (rc == OK) {
		status = commit_transaction(dbc);
	} else {
		status = rollback_transaction(dbc);
	}

	return status;
}
