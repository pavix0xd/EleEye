#ifndef DB_H
#define DB_H

#include <sql.h>
#include <sqlext.h>
#include "core.h"

// load all cameras into a "list" struct from the given ODBC connection string.
// on success, returns SQL_SUCCESS and fills list->cameras and list->count
SQLRETURN load_camera_list_odbc(const char *conn_str,
                                CameraList *list);

void free_camera_list(CameraList *list);

#endif