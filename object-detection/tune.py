from ultralytics import YOLO
from ultralytics.data.augment import Albumentations
from ray import tune
import wandb
import image_augmentation

# TODO: get your API key and use github secrets to access the key
wandb.login(key="<API_KEY>")

model = YOLO("yolov8m.pt")

# hyperparameter ranges and values are mostly YOLO defaults, however
# they are explicitly listed for clarity
search_space = {
    "lr0" : tune.loguniform(1e-4,1e-2),
    "lrf" : tune.uniform(0.1,0.5),
    "cos_lr" : True,
    "batch_size" : tune.choice([16,32,64]),
    "imgsz" : tune.choice([416,512,640,704,768,832]),
    "weight_decay" : tune.loguniform(1e-4,1e-3),
    "dropout" : tune.uniform(0.0,0.2),
    "optimizer" : tune.choice(["SGD","Adam","AdamW"]),
    "grad_clip" : tune.uniform(5.0,10.0),
    "box_loss" : tune.uniform(5.0,10.0),
    "cls_loss" : tune.uniform(0.25,1.0)
}

# hyperparameter dictionary that disables all built-in 
# YOLO image augmentations
hyp_no_aug = {
    'mosaic': 0.0,
    'mixup': 0.0,
    'degrees': 0.0,
    'translate': 0.0,
    'scale': 0.0,
    'shear': 0.0,
    'perspective': 0.0,
    'flipud': 0.0,
    'fliplr': 0.0,
    'hsv_h': 0.0,
    'hsv_s': 0.0,
    'hsv_v': 0.0
}

# Uses the Albumentations class (wrapper) of the augment package, 
# to incorperate albumentations augmentations directly into the 
# training data
augmentation_wrapper = Albumentations(pipeline=image_augmentation.main_pipeline)

model.tune(
    model="placeholder.yaml",
    data="placeholder.yaml",
    project="placeholder-project",
    name="placeholder-run-name",
    epochs=30,
    patience=10,
    save=True,
    save_period=5,
    resume=True,
    use_ray=True,
    space= search_space,
    hyp = hyp_no_aug,
    cos_lr=True,
    amp=True
)