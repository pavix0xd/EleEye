#ifndef CALLBACKS_H
#define CALLBACKS_H

#include <gst/gst.h>
#include <gstnvdsmeta.h>

void
on_rtspsrc_pad_added(GstElement *rtspsrc,
                     GstPad *newPad,
                     gpointer user_data);

void
on_rtspsrc_pad_removed(GstElement *rtspsrc,
                      GstPad *oldPad,
                      gpointer user_data);


gboolean
bus_call(GstBus *bus,
         GstMessage *msg,
         gpointer data);


void
alert_worker(gpointer data, gpointer user_data);


void
init_alert_pool(void);


void
shutdown_alert_pool(void);

GstPadProbeReturn
fake_sink_pad_buffer_probe(GstPad *pad,
                           GstPadProbeInfo *info,
                           gpointer u_data);

gboolean
reconnect_camera_bin(gpointer user_data);


gboolean
remove_camera_bin(gpointer user_data);


void
add_location_meta(NvDsFrameMeta *frame_meta, double latitude, double longitude);


GstPadProbeReturn
location_meta_probe(GstPad          *pad,
                    GstPadProbeInfo *info,
                    gpointer         u_data);
#endif