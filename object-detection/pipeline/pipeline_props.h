#ifndef PIPELINE_PROPS_H
#define PIPELINE_PROPS_H

/* RTSPSRC properties */

#define RTSP_PROP_URI                 "location"
#define RTSP_PROP_DROP_ON_LATENCY     "drop-on-latency"
#define RTSP_PROP_LATENCY             "latency"
#define RTSP_PROP_RETRY               "retry"
#define RTSP_PROP_TCP_TIMEOUT         "tcp-timeout"
#define RTSP_PROP_DO_RTSP_KEEP_ALIVE  "do-rtsp-keep-alive"
#define RTSP_PROP_CONNECTION_SPEED    "connection-speed"

#define RTSP_VAL_URI                  "rtsp://192.168.1.6:8554/stream"
#define RTSP_VAL_DROP_ON_LATENCY      FALSE
#define RTSP_VAL_LATENCY              2000
#define RTSP_VAL_RETRY                0
#define RTSP_VAL_TCP_TIMEOUT          0
#define RTSP_VAL_DO_RTSP_KEEP_ALIVE   TRUE
#define RTSP_VAL_CONNECTION_SPEED     0


/* Nvstreammux properties */

#define SM_PROP_GPU_ID                "gpu-id"
#define SM_PROP_LIVE_SOURCE           "live-source"
#define SM_PROP_BATCH_SIZE            "batch-size"
#define SM_PROP_BATCHED_PUSH_TIMEOUT  "batched-push-timeout"
#define SM_PROP_WIDTH                 "width"
#define SM_PROP_HEIGHT                "height"
#define SM_PROP_ENABLE_PADDING        "enable-padding"
#define SM_PROP_NVBUF_MEMORY_TYPE     "nvbuf-memory-type"


#define SM_VAL_GPU_ID                 0
#define SM_VAL_LIVE_SOURCE            TRUE
#define SM_VAL_BATCH_SIZE             2
#define SM_VAL_BATCHED_PUSH_TIMEOUT   40000
#define SM_VAL_WIDTH                  640 
#define SM_VAL_HEIGHT                 640
#define SM_VAL_ENABLE_PADDING         FALSE
#define SM_VAL_NVBUF_MEMORY_TYPE      0

/* Nvinfer properties */
#define GIE_PROP_CONFIG_FILE_PATH     "config-file-path"
#define GIE_PROP_GPU_ID               "gpu-id"
#define GIE_PROP_BATCH_SIZE           "batch-size"
#define GIE_PROP_INTERVAL             "interval"
#define GIE_PROP_NETWORK_MODE         "network-mode"
#define GIE_PROP_NUM_DETECTED_CLASSES "num-detected-classes"
#define GIE_PROP_PROCESS_MODE         "process-mode"
#define GIE_PROP_NETWORK_TYPE         "network-type"
#define GIE_PROP_CLUSTER_MODE         "cluster-mode"
#define GIE_PROP_MAINTAIN_ASPECT      "maintain-aspect-ratio"
#define GIE_PROP_SYMMETRIC_PADDING    "symmetric-padding"
#define GIE_PROP_PARSE_BBOX_FUNC_NAME "parse-bbox-func-name"
#define GIE_PROP_CUSTOM_LIB_PATH      "custom-lib-path"
#define GIE_PROP_ENGINE_CREATE_FUNC   "engine-create-func-name"

#define GIE_VAL_CONFIG_FILE_PATH      "/workspace/config_infer_primary_yoloV8.txt"
#define GIE_VAL_GPU_ID                0
#define GIE_VAL_BATCH_SIZE            2
#define GIE_VAL_INTERVAL              0
#define GIE_VAL_NETWORK_MODE          2
#define GIE_VAL_NUM_DETECTED_CLASSES  80
#define GIE_VAL_PROCESS_MODE          1
#define GIE_VAL_NETWORK_TYPE          0
#define GIE_VAL_CLUSTER_MODE          2
#define GIE_VAL_MAINTAIN_ASPECT       TRUE
#define GIE_VAL_SYMMETRIC_PADDING     TRUE
#define GIE_VAL_PARSE_BBOX_FUNC_NAME  "NvDsInferParseYolo"
#define GIE_VAL_CUSTOM_LIB_PATH       "/workspace/DeepStream-Yolo/nvdsinfer_custom_impl_Yolo/libnvdsinfer_custom_impl_Yolo.so"
#define GIE_VAL_ENGINE_CREATE_FUNC    "NvDsInferYoloCudaEngineGet"

#endif // PIPELINE_PROPS_H
