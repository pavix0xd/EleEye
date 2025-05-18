#include <sql.h>
#include <sqlext.h>
#include <string.h>
#include <stdio.h>
#include "core.h"

// Helper function to parse status string into enum

static CameraStatus parse_status(const char *status)
{
    if (strcmp(status, "up") == 0) return CAMERA_STATUS_UP;
    if (strcmp(status, "maintenance") == 0) return CAMERA_STATUS_MAINTENANCE;

    return CAMERA_STATUS_DOWN;
}


SQLRETURN load_camera_list_odbc(const char *conn_str, CameraList *list)
{
    SQLHENV env = SQL_NULL_HENV;
    SQLHDBC dbc = SQL_NULL_HDBC;
    SQLHSTMT stmt = SQL_NULL_HSTMT;
    SQLRETURN ret;

    list->cameras = NULL;
    list->count = 0;
    int capacity = 0;

    // allocate environment handle
    ret = SQLAllocHandle(SQL_HANDLE_ENV, SQL_NULL_HANDLE, &env);

    if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) goto cleanup;
    SQLSetEnvAttr(env, SQL_ATTR_ODBC_VERSION, (void*)SQL_OV_ODBC3, 0);

    // allocate connection handle
    ret = SQLAllocHandle(SQL_HANDLE_DBC, env, &dbc);
    if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) goto cleanup;

    // connect using the provided connection string
    ret = SQLDriverConnect(dbc, NULL,
                           (SQLCHAR*)conn_str, SQL_NTS,
                            NULL, 0, NULL,
                            SQL_DRIVER_COMPLETE);
    if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) goto cleanup;

    // allocate statement
    ret = SQLAllocHandle(SQL_HANDLE_STMT, dbc, &stmt);
    if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) goto cleanup;

    // execute query
    ret = SQLExecDirect(stmt, (SQLCHAR*)"SELECT id, name, uri, status, latitude, longitude FROM Cameras", SQL_NTS);
    if (ret != SQL_SUCCESS && ret != SQL_SUCCESS_WITH_INFO) goto cleanup;


    while ((ret = SQLFetch(stmt)) == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO)
    {
        SQLINTEGER id;
        SQLCHAR name_buff[256] = {0};
        SQLCHAR uri_buff[512] = {0};
        SQLCHAR stat_buff[64] = {0};
        SQLDOUBLE latitude = 0.0;
        SQLDOUBLE longitude = 0.0;

        SQLGetData(stmt, 1, SQL_C_SLONG, &id, 0, NULL);
        SQLGetData(stmt, 2, SQL_C_CHAR, name_buff, sizeof(name_buff), NULL);
        SQLGetData(stmt, 3, SQL_C_CHAR, uri_buff, sizeof(uri_buff), NULL);
        SQLGetData(stmt, 4, SQL_C_CHAR, stat_buff, sizeof(stat_buff), NULL);
        SQLGetData(stmt, 5, SQL_C_DOUBLE, &latitude, 0, NULL);
        SQLGetData(stmt, 6, SQL_C_DOUBLE, &longitude, 0, NULL);


        if (list->count >= capacity)
        {
            capacity = capacity ? capacity * 2 : 4;
            CameraInfo *tmp = realloc(list->cameras, capacity * sizeof(CameraInfo));
            
            if (!tmp)
            {
                ret = SQL_ERROR;
                goto cleanup;
            }

            list->cameras = tmp;
        }


        CameraInfo *camera_info = &list->cameras[list->count++];
        camera_info->camera_id= (int)id;
        camera_info->camera_name = strdup((char*)name_buff);
        camera_info->camera_uri = strdup((char*)uri_buff);
        camera_info->camera_status = parse_status((char*)stat_buff);
        camera_info->camera_latitude = (double) latitude;
        camera_info->camera_longitude = (double) longitude;
    }

    ret = SQL_SUCCESS;

cleanup:
    if (stmt != SQL_NULL_HSTMT) SQLFreeHandle(SQL_HANDLE_STMT, stmt);

    if (dbc != SQL_NULL_HDBC)
    {
        SQLDisconnect(dbc);
        SQLFreeHandle(SQL_HANDLE_DBC, dbc);
    }

    if (env != SQL_NULL_HENV)
    {
        SQLFreeHandle(SQL_HANDLE_ENV, env);
    }

    return ret;
}


void free_camera_list(CameraList *list)
{
    for (int i = 0; i < list->count; ++i)
    {
        free(list->cameras[i].camera_name);
        free(list->cameras[i].camera_uri);
    }

    free(list->cameras);
}