#include <gst/gst.h>
#include <glib.h>
#include "pipeline_props.h"
#include "callbacks.h"
#include "core.h"
#include "db.h"

CameraBin *create_camera_src_bin(const gchar *name,
                              const gchar *uri)
{
    CameraBin *camera_bin;
    GstElement *bin, *rtspsrc, *depay, *parse, *decoder, *queue;
    GstPad *queue_src_pad, *ghost_pad;

    camera_bin = g_malloc0(sizeof(*camera_bin));
    camera_bin->retries = 0;
    camera_bin->uri = g_strdup(uri);

    bin = gst_bin_new(name);

    gchar *element_name = g_strdup_printf("%s-rtsp-source", name);
    rtspsrc = gst_element_factory_make("rtspsrc", element_name);
    g_free(element_name);

    element_name = g_strdup_printf("%s-rtp-h264-depay", name);
    depay = gst_element_factory_make("rtph264depay", element_name);
    g_free(element_name);

    element_name = g_strdup_printf("%s-h264-parse", name);
    parse = gst_element_factory_make("h264parse", element_name);
    g_free(element_name);

    element_name = g_strdup_printf("%s-hw-decoder", name);
    decoder = gst_element_factory_make("nvv4l2decoder", element_name);
    g_free(element_name);

    element_name = g_strdup_printf("%s-camera-queue", name);
    queue = gst_element_factory_make("queue", element_name);
    g_free(element_name);


    if (!bin || !rtspsrc || !depay || !parse || !decoder || !queue)
    {
        g_printerr("Failed to create one or more elements for camera bin '%s'\n", name);

        if (queue) gst_object_unref(queue);
        if (decoder) gst_object_unref(decoder);
        if (parse) gst_object_unref(parse);
        if (depay) gst_object_unref(depay);
        if (rtspsrc) gst_object_unref(rtspsrc);
        if (bin) gst_object_unref(bin);

        g_free(camera_bin->uri);
        g_free(camera_bin);
        return NULL;
    }

    g_object_set(rtspsrc,
        RTSP_PROP_URI,                 uri,
        RTSP_PROP_DROP_ON_LATENCY,     RTSP_VAL_DROP_ON_LATENCY,
        RTSP_PROP_LATENCY,             RTSP_VAL_LATENCY,
        RTSP_PROP_RETRY,               RTSP_VAL_RETRY,
        RTSP_PROP_TCP_TIMEOUT,         RTSP_VAL_TCP_TIMEOUT,
        RTSP_PROP_DO_RTSP_KEEP_ALIVE,  RTSP_VAL_DO_RTSP_KEEP_ALIVE,
        RTSP_PROP_CONNECTION_SPEED,    RTSP_VAL_CONNECTION_SPEED,
        NULL
    );

    gst_bin_add_many(GST_BIN(bin),
                     rtspsrc,
                     depay,
                     parse,
                     decoder,
                     queue,
                     NULL);



    // Link the internal static chain. note that rtspsrc -> depay is linked
    // dynamically via pad-added
    if (!gst_element_link_many(depay, parse, decoder, queue, NULL))
    {
        g_printerr("Failed to link depay->parse->decoder->queue inside %s\n", name);
        gst_object_unref(bin);
        g_free(camera_bin->uri);
        g_free(camera_bin);
        return NULL;
    }

    g_object_set(queue, "max-size-buffers", 4, "leaky", 2, NULL);

    // hookup dynamic pads: rtspsrc -> depay
    g_signal_connect(rtspsrc, "pad-added",
                     G_CALLBACK(on_rtspsrc_pad_added), depay);
    

    g_signal_connect(rtspsrc, "pad-removed",
                     G_CALLBACK(on_rtspsrc_pad_removed), depay);


    queue_src_pad = gst_element_get_static_pad(queue, "src");
    ghost_pad = gst_ghost_pad_new("src", queue_src_pad);
    gst_element_add_pad(bin, ghost_pad);
    gst_object_unref(queue_src_pad);

    camera_bin->bin = bin;
    camera_bin->rtspsrc = rtspsrc;
    camera_bin->depay = depay;

    return camera_bin;
}



static void free_camera_bin(gpointer data)
{
    CameraBin *camera_bin = (CameraBin*)data;
    g_free(camera_bin->uri);
    g_free(camera_bin);
}


int main(int argc, char *argv[])
{
    gst_init(&argc, &argv);
    GMainLoop *loop = g_main_loop_new(NULL, FALSE);
    init_alert_pool();

    // initialize pipeline elements
    GstPipeline *pipeline = GST_PIPELINE(gst_pipeline_new("deepstream-pipeline"));
    GstElement  *streammux  = gst_element_factory_make("nvstreammux",   "stream-muxer");
    GstElement  *infer      = gst_element_factory_make("nvinfer",       "primary-infer");
    GstElement  *sink       = gst_element_factory_make("fakesink",      "fake-sink");


    // configure pipeline element properties
    g_object_set(streammux,
        SM_PROP_GPU_ID,               SM_VAL_GPU_ID,
        SM_PROP_LIVE_SOURCE,          SM_VAL_LIVE_SOURCE,
        SM_PROP_BATCH_SIZE,           SM_VAL_BATCH_SIZE,
        SM_PROP_BATCHED_PUSH_TIMEOUT, SM_VAL_BATCHED_PUSH_TIMEOUT,
        SM_PROP_WIDTH,                SM_VAL_WIDTH,
        SM_PROP_HEIGHT,               SM_VAL_HEIGHT,
        SM_PROP_ENABLE_PADDING,       SM_VAL_ENABLE_PADDING,
        SM_PROP_NVBUF_MEMORY_TYPE,    SM_VAL_NVBUF_MEMORY_TYPE,
        NULL
    );

    g_object_set(infer,
        GIE_PROP_CONFIG_FILE_PATH,    GIE_VAL_CONFIG_FILE_PATH,
        GIE_PROP_GPU_ID,              GIE_VAL_GPU_ID,
        GIE_PROP_BATCH_SIZE,          GIE_VAL_BATCH_SIZE,
        GIE_PROP_INTERVAL,            GIE_VAL_INTERVAL,
        NULL
    );

    // link nvstreammux -> nvinfer -> fakesink
    gst_bin_add_many(GST_BIN(pipeline), streammux, infer, sink, NULL);

    if (!gst_element_link_many(streammux, infer, sink, NULL)) 
    {
        g_printerr("Failed to link streammux → infer → sink\n");
        return -1;
    }

    // setting up application context with a g_list of all camera bin elements
    AppContext application_context = 
    {
        .pipeline    = pipeline,
        .streammux   = streammux,
        .camera_bins = NULL,
        .loop        = loop
    };

    // load camera records from the database
    CameraList camera_list = { .cameras = NULL, .count = 0 };
    if (load_camera_list_odbc("DSN=TestSQLite;", &camera_list) != SQL_SUCCESS) 
    {
        g_printerr("Error: could not load cameras from DB\n");
        return -1;
    }

    // create a camera bin element for each camera that is up
    for (int i = 0; i < camera_list.count; i++) 
    {
        CameraInfo *ci = &camera_list.cameras[i];
        if (ci->camera_status != CAMERA_STATUS_UP) continue;

        CameraBin *cb = create_camera_src_bin(ci->camera_name, ci->camera_uri);

        if (!cb) 
        {
            g_printerr("Failed to create bin for %s\n", ci->camera_name);
            continue;
        }

        gchar pad_name[32];
        g_snprintf(pad_name, sizeof(pad_name), "sink_%d", i);

        cb->mux_sink_pad     = gst_element_get_request_pad(streammux, pad_name);
        cb->latitude         = ci->camera_latitude;
        cb->longitude        = ci->camera_longitude;
        cb->detection_count  = 0;
        cb->window_start_time = 0;
        cb->window_ms        = 60000;           // set 1 min alert window
        cb->streammux        = streammux;
        cb->pipeline         = GST_ELEMENT(pipeline);

        gst_bin_add(GST_BIN(pipeline), cb->bin);
        gst_element_sync_state_with_parent(cb->bin);

        GstPad *src_pad = gst_element_get_static_pad(cb->bin, "src");


        if (gst_pad_link(src_pad, cb->mux_sink_pad) != GST_PAD_LINK_OK) 
        {
            g_printerr("Failed to link %s → streammux\n", ci->camera_name);
        }


        gst_object_unref(src_pad);

        application_context.camera_bins = g_list_append(application_context.camera_bins, cb);
    }


    free_camera_list(&camera_list);


    // Attach location metatada callback which injects location
    // metadata to each respective frame
    {
        GstPad *mux_src_pad = gst_element_get_static_pad(streammux, "src");
        gst_pad_add_probe(
            mux_src_pad,
            GST_PAD_PROBE_TYPE_BUFFER,
            location_meta_probe,
            &application_context,
            NULL
        );
        gst_object_unref(mux_src_pad);
    }


    // Attach inference metadata callback which retrieves inference
    // metadata to send HTTP Post alerts
    {
        GstPad *sink_pad = gst_element_get_static_pad(sink, "sink");
        gst_pad_add_probe(
            sink_pad,
            GST_PAD_PROBE_TYPE_BUFFER,
            fake_sink_pad_buffer_probe,
            &application_context,
            NULL
        );
        gst_object_unref(sink_pad);
    }


    // adding bus watch
    GstBus *bus = gst_pipeline_get_bus(pipeline);
    gst_bus_add_watch(bus, bus_call, &application_context);
    gst_object_unref(bus);

    // starting the pipeline for inference
    gst_element_set_state(GST_ELEMENT(pipeline), GST_STATE_PLAYING);
    g_main_loop_run(loop);

    // cleanup
    shutdown_alert_pool();
    gst_element_set_state(GST_ELEMENT(pipeline), GST_STATE_NULL);
    gst_object_unref(pipeline);
    g_main_loop_unref(loop);
    g_list_free_full(application_context.camera_bins, free_camera_bin);
    return 0;
}