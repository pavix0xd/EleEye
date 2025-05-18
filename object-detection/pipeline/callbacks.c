#include <gst/gst.h>
#include <glib.h>
#include <gstnvdsmeta.h>
#include <nvdsmeta_schema.h>
#include <curl/curl.h>
#include "callbacks.h"
#include "core.h"
#include "pipeline_props.h"


// define which class we are targeting
#ifndef DESIRED_CLASS_ID
#define DESIRED_CLASS_ID 0
#endif


// pointer to HTTP alert threadpool used by the alert callbacks
static GThreadPool *alert_pool = NULL;


void
on_rtspsrc_pad_added(GstElement *rtspsrc, GstPad *newPad, gpointer user_data)
{
    GstElement *depay = GST_ELEMENT(user_data);
    GstPad     *sinkPad = gst_element_get_static_pad(depay, "sink");
    GstPadLinkReturn ret;
    GstStructure *new_pad_caps_struct = NULL;
    gchar *new_pad_caps_string = NULL;

    g_print("Received new pad '%s' from '%s'\n",
             gst_pad_get_name(newPad), gst_element_get_name(rtspsrc));

    // Get the capabilities of the new pad to ensure its the one we want to link,
    // also printing it out for debugging
    GstCaps *new_pad_caps = gst_pad_get_current_caps(newPad);
    if (new_pad_caps)
    {
      new_pad_caps_struct = gst_caps_get_structure(new_pad_caps, 0);
      new_pad_caps_string = gst_structure_to_string(new_pad_caps_struct);

      g_print("Pad capabilities: %s\n", new_pad_caps_string);
      g_free(new_pad_caps_string);
      gst_caps_unref(new_pad_caps);
    }


    // Check if the sinkpad is already linked. if the pad was removed and
    // readded due to stream interruption, the depayloader sink pad might be
    // still linked to the old source pad of the RTSP source element. We must 
    // unlink it if so.
    if (gst_pad_is_linked(sinkPad))
    {
      GstPad *peer = gst_pad_get_peer(sinkPad);

      if (peer)
      {
        g_print("Sink pad '%s' is already linked to '%s'. Unlinking...\n",
                 gst_pad_get_name(sinkPad), gst_element_get_name(depay));
        
        gst_pad_unlink(peer, sinkPad);
        gst_object_unref(peer);
        
      }
    }

    ret = gst_pad_link(newPad, sinkPad);
    
    if (GST_PAD_LINK_FAILED(ret)) 
    {
        g_printerr("RTSP source pad %s could not be linked to depayloader\n",
                   gst_pad_get_name(newPad));
    } 
    
    else 
    {
        g_print("RTSP source pad %s linked to depayloader\n",
                gst_pad_get_name(newPad));
        
        // maybe signal the pipeline that it can proceed to 
        // the PLAYING state after this occurs 
    }

    gst_object_unref(sinkPad);
}


void
on_rtspsrc_pad_removed(GstElement *rtspsrc, GstPad *oldPad, gpointer user_data)
{
    GstElement *depay = GST_ELEMENT(user_data);
    GstPad     *sinkPad = gst_element_get_static_pad(depay, "sink");


    g_print("RTSP source pad %s removed from '%s'\n",
             gst_pad_get_name(oldPad), gst_element_get_name(rtspsrc));
    

    if (gst_pad_is_linked(oldPad) && gst_pad_get_peer(oldPad) == sinkPad)
    {
      gst_pad_unlink(oldPad, sinkPad);
      g_print("Forced unlink of RTSP source pad %s from depayloader\n",
               gst_pad_get_name(oldPad));
    }

    else
    {
      g_print("RTSP source pad %s was not linked to depayloader or already unlinked\n",
              gst_pad_get_name(oldPad));
    }

    gst_object_unref(sinkPad);

}


gboolean
bus_call(GstBus     *bus,
         GstMessage *msg,
         gpointer    data)
{
    AppContext *ctx = (AppContext*)data;
    GstObject  *src = GST_MESSAGE_SRC(msg);

    switch (GST_MESSAGE_TYPE(msg)) {
    case GST_MESSAGE_EOS:
        g_print("*** EOS Received (pipeline stays alive)\n");
        break;

    case GST_MESSAGE_ERROR: {
        GError *err = NULL;
        gchar  *dbg = NULL;

        gst_message_parse_error(msg, &err, &dbg);
        g_printerr(">>> bus_call got ERROR from %s: %s\n",
                   GST_OBJECT_NAME(src),
                   err ? err->message : "(no message)");

        if (dbg) {
            g_printerr("    DEBUG INFO: %s\n", dbg);
            g_free(dbg);
        }

        /* 1) Try to match this error to one of our camera bins */
        CameraBin *matched      = NULL;
        GList     *matched_link = NULL;
        guint       idx         = 0;

        for (GList *l = ctx->camera_bins; l; l = l->next, ++idx) {
            CameraBin *cb = (CameraBin*)l->data;
            g_print("    checking bin[%u]=%s, rtspsrc=%p, src=%p\n",
                    idx,
                    GST_ELEMENT_NAME(cb->bin),
                    (void*)cb->rtspsrc,
                    (void*)src);
            if (GST_OBJECT(src) == GST_OBJECT(cb->rtspsrc)) {
                matched      = cb;
                matched_link = l;
                g_print("    --> matched camera bin[%u]=%s\n",
                        idx, GST_ELEMENT_NAME(cb->bin));
                break;
            }
        }

        if (matched) {
            /* 2) We have an RTSP‐source error for bin ‘matched’ */
            if (matched->retries < MAX_RETRIES) {
                matched->retries++;
                g_print("[%-10s] RTSP error, retrying %u/%d\n",
                        GST_ELEMENT_NAME(matched->bin),
                        matched->retries, MAX_RETRIES);

                /* flush that stream */
                GstPad *ghost = gst_element_get_static_pad(matched->bin, "src");
                gst_pad_send_event(ghost, gst_event_new_flush_start());
                gst_pad_send_event(ghost, gst_event_new_flush_stop(FALSE));
                gst_object_unref(ghost);

                g_idle_add((GSourceFunc)reconnect_camera_bin, matched);
            } else {
                g_printerr("[%-10s] Max retries reached (%u), removing bin\n",
                           GST_ELEMENT_NAME(matched->bin),
                           matched->retries);

                /* remove it */
                ctx->camera_bins =
                    g_list_delete_link(ctx->camera_bins, matched_link);
                g_idle_add((GSourceFunc)remove_camera_bin, matched);
            }
        } else {
            /* 3) Not an RTSP‐source error, fall back to original logic */
            g_printerr("    This error is not from any rtspsrc, aborting pipeline\n");
            g_main_loop_quit(ctx->loop);
        }

        if (err)
            g_error_free(err);
        break;
    }

    case GST_MESSAGE_WARNING: 
    {
        GError  *warn = NULL;
        gchar   *dbg  = NULL;
        GstObject *src = GST_MESSAGE_SRC(msg);

        /* 1) Parse and print the warning */
        gst_message_parse_warning(msg, &warn, &dbg);
        g_printerr(">>> WARNING from %s: %s\n",
                GST_OBJECT_NAME(src),
                warn ? warn->message : "(no message)");
        if (dbg) {
            g_printerr("    DEBUG INFO: %s\n", dbg);
            g_free(dbg);
        }

        /* 2) Check if this warning came from one of our camera bins' rtspsrc */
        CameraBin *matched      = NULL;
        GList     *matched_link = NULL;
        for (GList *l = ctx->camera_bins; l; l = l->next) {
            CameraBin *cb = (CameraBin*)l->data;
            if (GST_OBJECT(src) == GST_OBJECT(cb->rtspsrc)) {
                matched      = cb;
                matched_link = l;
                break;
            }
        }

        if (matched) {
            /* 3) Flush that camera’s stream */
            GstPad *ghost = gst_element_get_static_pad(matched->bin, "src");
            gst_pad_send_event(ghost, gst_event_new_flush_start());
            gst_pad_send_event(ghost, gst_event_new_flush_stop(FALSE));
            gst_object_unref(ghost);

            /* 4) Retry or remove */
            if (matched->retries < MAX_RETRIES) {
                matched->retries++;
                g_print("[%-10s] RTSP warning, retrying %u/%u\n",
                        GST_ELEMENT_NAME(matched->bin),
                        matched->retries, MAX_RETRIES);
                g_idle_add((GSourceFunc)reconnect_camera_bin, matched);
            } else {
                g_printerr("[%-10s] Max retries reached (%u), removing bin\n",
                        GST_ELEMENT_NAME(matched->bin),
                        matched->retries);
                ctx->camera_bins =
                g_list_delete_link(ctx->camera_bins, matched_link);
                g_idle_add((GSourceFunc)remove_camera_bin, matched);
            }
        }
        /* else: leave non-RTSP warnings alone */

        if (warn)
            g_error_free(warn);
        break;
    }

    case GST_MESSAGE_STATE_CHANGED: {
        GstState olds, news, pend;
        gst_message_parse_state_changed(msg, &olds, &news, &pend);
        g_print(">>> STATE_CHANGED: %s %s → %s\n",
                GST_OBJECT_NAME(msg->src),
                gst_element_state_get_name(olds),
                gst_element_state_get_name(news));
        break;
    }

    default:
        break;
    }

    return TRUE;
}


// callback which sends an HTTP POST alert
void
alert_worker(gpointer data, gpointer user_data)
{
    AlertTask *task = data;
    CameraBin *cb   = task->camera_bin;
    gint        id  = task->class_id;

    CURL *curl = curl_easy_init();
    if (curl) {
        char body[256];
        snprintf(body, sizeof(body),
            "{\"camera\":\"%s\",\"class\":%d,\"lat\":%.6f,\"lon\":%.6f}",
            GST_ELEMENT_NAME(cb->bin), id,
            cb->latitude, cb->longitude);

        curl_easy_setopt(curl, CURLOPT_URL, "http://your.server/alert");
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body);
        curl_easy_perform(curl);
        curl_easy_cleanup(curl);
    }

    g_free(task);
}


void
init_alert_pool(void)
{
    alert_pool = g_thread_pool_new(
        alert_worker,
        NULL,
        4,
        FALSE,
        NULL
    );

    curl_global_init(CURL_GLOBAL_ALL);
}


void
shutdown_alert_pool(void)
{
    if (alert_pool)
    {
        g_thread_pool_free(alert_pool, FALSE, TRUE);
        alert_pool = NULL;
    }

    curl_global_cleanup();
}


// callback which parses batch inference metadata
GstPadProbeReturn
fake_sink_pad_buffer_probe(GstPad          *pad,
                           GstPadProbeInfo *info,
                           gpointer         u_data)
{
    GstBuffer *buffer = GST_PAD_PROBE_INFO_BUFFER(info);
    if (!buffer) return GST_PAD_PROBE_OK;

    AppContext *ctx = (AppContext*)u_data;

    NvDsBatchMeta *batch_meta = gst_buffer_get_nvds_batch_meta(buffer);

    for (NvDsMetaList *l_frame = batch_meta->frame_meta_list;
         l_frame; l_frame = l_frame->next)
    {
        NvDsFrameMeta *fmeta = (NvDsFrameMeta*)l_frame->data;
        guint source_id = fmeta->pad_index;

        CameraBin *cb = g_list_nth_data(ctx->camera_bins, source_id);
        if (!cb) continue;

        guint64 now = g_get_monotonic_time() / 1000;
        if (cb->window_start_time == 0 ||
            now - cb->window_start_time >= cb->window_ms)
        {
            cb->window_start_time = now;
            cb->detection_count   = 0;
        }

        for (NvDsMetaList *l_obj = fmeta->obj_meta_list;
             l_obj; l_obj = l_obj->next)
        {
            NvDsObjectMeta *obj = (NvDsObjectMeta*)l_obj->data;
            if (obj->class_id != DESIRED_CLASS_ID)
                continue;

            cb->detection_count++;

            if (cb->detection_count == 1 && alert_pool)
            {
                AlertTask *task = g_new0(AlertTask, 1);
                task->camera_bin = cb;
                task->class_id   = obj->class_id;
                g_thread_pool_push(alert_pool, task, NULL);
            }
        }
    }

    return GST_PAD_PROBE_OK;
}

// callback which replaces the camera bin's RTSP source element with a 
// new one for reconnection
gboolean
reconnect_camera_bin(gpointer user_data)
{
  CameraBin *camera_bin = (CameraBin*)user_data;
  GstElement *depay = camera_bin->depay;

  gst_element_set_state(camera_bin->bin, GST_STATE_PAUSED);

  gst_element_set_state(camera_bin->rtspsrc, GST_STATE_NULL);
  gst_bin_remove(GST_BIN(camera_bin->bin), camera_bin->rtspsrc);
  gst_object_unref(camera_bin->rtspsrc);

  gchar *element_name = g_strdup_printf("%s-rtsp-source",
                                        GST_ELEMENT_NAME(camera_bin->bin));
  
  
  camera_bin->rtspsrc = gst_element_factory_make("rtspsrc", element_name);
  g_free(element_name);


  g_object_set(camera_bin->rtspsrc,
    RTSP_PROP_URI,                  camera_bin->uri,
    RTSP_PROP_DROP_ON_LATENCY,      RTSP_VAL_DROP_ON_LATENCY,
    RTSP_PROP_LATENCY,              RTSP_VAL_LATENCY,
    RTSP_PROP_RETRY,                RTSP_VAL_RETRY,
    RTSP_PROP_TCP_TIMEOUT,          RTSP_VAL_TCP_TIMEOUT,
    RTSP_PROP_DO_RTSP_KEEP_ALIVE,   RTSP_VAL_DO_RTSP_KEEP_ALIVE,
    RTSP_PROP_CONNECTION_SPEED,     RTSP_VAL_CONNECTION_SPEED,
    NULL);
 

  gst_bin_add(GST_BIN(camera_bin), camera_bin->rtspsrc);

  g_signal_connect(camera_bin->rtspsrc, "pad-added",
                   G_CALLBACK(on_rtspsrc_pad_added), depay);

  g_signal_connect(camera_bin->rtspsrc, "pad-removed",
                   G_CALLBACK(on_rtspsrc_pad_removed), depay);
  

  gst_element_sync_state_with_parent(camera_bin->rtspsrc);
  gst_element_sync_state_with_parent(camera_bin->bin);

  gst_element_set_state(camera_bin->bin, GST_STATE_PLAYING);

  return FALSE;
}


// callback for completely removing a certain camera bin from the 
// "main" pipeline. 
gboolean
remove_camera_bin(gpointer user_data)
{
  CameraBin *camera_bin = (CameraBin*)user_data;
  GstElement *pipeline = camera_bin->pipeline;
  GstElement *streammux = camera_bin->streammux;
  GstPad *ghost = gst_element_get_static_pad(camera_bin->bin, "src");

  gst_element_set_state(camera_bin->bin, GST_STATE_NULL);

  if (gst_pad_is_linked(ghost))
  {
    gst_pad_unlink(ghost, camera_bin->mux_sink_pad);
  }
  gst_object_unref(ghost);

  gst_element_release_request_pad(streammux, camera_bin->mux_sink_pad);
  gst_object_unref(camera_bin->mux_sink_pad);

  gst_bin_remove(GST_BIN(pipeline), camera_bin->bin);
  gst_object_unref(camera_bin->bin);

  g_free(camera_bin->uri);
  g_free(camera_bin);

  return FALSE;
}

// helper function to attach Location Metadata to a single frame
void
add_location_meta(NvDsFrameMeta *frame_meta,
                  double         latitude,
                  double         longitude)
{
    NvDsBatchMeta *batch_meta = frame_meta->base_meta.batch_meta;
    NvDsUserMeta  *user_meta  = nvds_acquire_user_meta_from_pool(batch_meta);

    user_meta->user_meta_data = malloc(sizeof(LocationMeta));
    ((LocationMeta*)user_meta->user_meta_data)->latitude  = latitude;
    ((LocationMeta*)user_meta->user_meta_data)->longitude = longitude;

    user_meta->base_meta.meta_type = NVDS_USER_FRAME_META;
    nvds_add_user_meta_to_frame(frame_meta, user_meta);
}


// pad probe callback for adding location metadata
GstPadProbeReturn
location_meta_probe(GstPad          *pad,
                    GstPadProbeInfo *info,
                    gpointer         u_data)
{
    AppContext *ctx = (AppContext*)u_data;
    GstBuffer  *buf = GST_PAD_PROBE_INFO_BUFFER(info);

    if (!buf) return GST_PAD_PROBE_OK;

    NvDsBatchMeta *batch_meta = gst_buffer_get_nvds_batch_meta(buf);

    for (NvDsMetaList *l = batch_meta->frame_meta_list; l; l = l->next) 
    {
        NvDsFrameMeta *fmeta = (NvDsFrameMeta*)l->data;
        guint source_id = fmeta->pad_index;

        CameraBin *cb = g_list_nth_data(ctx->camera_bins, source_id);

        if (cb) 
        {
            add_location_meta(fmeta, cb->latitude, cb->longitude);
        }
    }

    return GST_PAD_PROBE_OK;
}