#ifndef CORE_H
#define CORE_H

#include <gst/gst.h>
#include <glib.h>

#define MAX_RETRIES 5


extern GThreadPool *alert_pool;


typedef struct AppContext
{
    GstPipeline *pipeline;
    GstElement *streammux;
    GList *camera_bins;
    GMainLoop *loop;
} AppContext;


typedef struct CameraBin
{
    GstElement *bin;
    GstElement *rtspsrc;
    GstPad *mux_sink_pad;
    GstElement *streammux;
    GstElement *pipeline;
    GstElement *depay;
    guint retries;
    gchar *uri;
    gdouble latitude;
    gdouble longitude;
    guint detection_count;
    guint64 window_start_time;
    guint window_ms;
} CameraBin;


typedef enum CameraStatus
{
    CAMERA_STATUS_UP,
    CAMERA_STATUS_DOWN,
    CAMERA_STATUS_MAINTENANCE
} CameraStatus;


typedef struct CameraInfo
{
    int camera_id;
    char *camera_name;
    char *camera_uri;
    CameraStatus camera_status;
    double camera_latitude;
    double camera_longitude;
} CameraInfo;


typedef struct CameraList
{
    CameraInfo *cameras;
    int count;
} CameraList;


typedef struct LocationMeta
{
    double latitude;
    double longitude;
} LocationMeta;


typedef struct AlertTask
{
    CameraBin *camera_bin;
    gint class_id;
} AlertTask;


#endif