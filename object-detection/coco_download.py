from coco_dataset import coco_dataset_download as cocod

class_name = "elephant"
image_count = 5000
annotations_path = "C:\\Users\\josem\\OneDrive\\Desktop\\annotations\\instances_val2017.json"

cocod.coco_dataset_download(class_name,image_count,annotations_path)