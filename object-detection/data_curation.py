import json, fileinput, sys, argparse, os, cv2, shutil, xml.etree.ElementTree as ET
from tqdm import tqdm
from loguru import logger

def parse_voc_annotation(xml_file: str) -> list[dict[str, any]] | None:

    try:
        # if the xml file cannot be parsed or opened, it must be assumed to 
        # be corrupted
        tree = ET.parse(xml_file)

        # if the annotation element cannot be found in the parsed/opened XML
        # file, it is missing important data and must be assumed as corrupted
        annotation_element = tree.getroot()
    
    except (FileNotFoundError, ET.ParseError):

        return None
    

    object_elements = annotation_element.findall('object')

    if not object_elements:
        return None

    bounding_boxes = []

    for object_element in object_elements:

        bndbox_element = object_element.find('bndbox')

        if bndbox_element:
            xmin = bndbox_element.find('xmin').text
            ymin = bndbox_element.find('ymin').text
            xmax = bndbox_element.find('xmax').text
            ymax = bndbox_element.find('ymax').text

            bounding_boxes.append(
                {"xmin" : xmin, 
                "ymin" : ymin, 
                "xmax" : xmax, 
                "ymax" : ymax}
            )

    return bounding_boxes

def validate_voc_annotation(image_width: int, 
                            image_height: int, 
                            bounding_boxes: list[dict[str,any]]) -> list[dict[str,float]] | None:

    if not bounding_boxes:
        return None

    yolo_bounding_boxes = []

    for bounding_box in bounding_boxes:

        try:
            xmin = int(bounding_box['xmin'])
            ymin = int(bounding_box['ymin'])
            xmax = int(bounding_box['xmax'])
            ymax = int(bounding_box['ymax'])

        except (ValueError, KeyError):
            continue

        if (xmin > image_width or xmin < 0 or
            xmax > image_width or xmax < 0 or
            ymin > image_height or ymin < 0 or
            ymax > image_height or ymax < 0):
            continue

        bounding_box_width = xmax - xmin
        bounding_box_height = ymax - ymin

        # calculate the midpoint coordinates of the bounding box
        x_center = xmin + (bounding_box_width / 2)
        y_center = ymin + (bounding_box_height / 2)

        # normalizing center coordinates, width and height of the 
        # bounding box
        x_center /= image_width
        y_center /= image_height
        bounding_box_width /= image_width
        bounding_box_height /= image_height

        yolo_bounding_boxes.append({
            "class" : 0,
            "center_x" : x_center,
            "center_y": y_center,
            "width": bounding_box_width,
            "height": bounding_box_height
        })

    return yolo_bounding_boxes if yolo_bounding_boxes else None

def parse_coco_annotation(image_file: str, coco_annotation_file: str) -> int | None:

    try:
        with open(coco_annotation_file, 'r', encoding='utf-8') as f:
            coco_annotation_data = json.load(f)
        
    except (FileNotFoundError, json.JSONDecodeError):
        return None
    
    # Retrieves array of image objects from the image property
    images = coco_annotation_data.get('images',[])

    # Uses linear search to find the image id associated
    # with the passed image. 
    for image in images:

        if image['file_name'] == image_file:
            return image.get('id')
    
    # if no image id is associated with the passed image,
    # the image is said to be orphaned
    return None

def validate_coco_annotation(image_width: int, 
                             image_height: int, 
                             image_id: int, 
                             coco_annotation_file: str) -> list[dict[str,any]] | None:

    try:
        with open(coco_annotation_file, 'r', encoding='utf-8') as f:
            coco_annotation_data = json.load(f)
    
    except (FileNotFoundError, json.JSONDecodeError):
        return None
    
    # Retrieves the array of annotation objects from the 
    # annotation property
    annotations = coco_annotation_data.get('annotations',[])
    yolo_bounding_boxes = []

    for annotation in annotations:

        try:
            annotation_image_id = int(annotation.get('image_id'))

        except (ValueError, TypeError):
            continue
        # If the annotation object's image id is the same 
        # as the image id passed, the annotation object is
        # parsed.
        if annotation_image_id == image_id:

            try:
                bbox = annotation.get('bbox')
                x_min = float(bbox[0])
                y_min = float(bbox[1])
                bounding_box_width = float(bbox[2])
                bounding_box_height = float(bbox[3])

            # if the bounding box itself, or its data is
            # malformed, the annotation is skipped. Any 
            # annotation that can be used, will be used. 
            except (TypeError, IndexError):
                continue

            # validate whether the bounding box data is valid
            # relative to the image's dimensions
            x_max = x_min + bounding_box_width
            y_max = y_min + bounding_box_height

            if (x_min > image_width or x_min < 0 or
                y_min > image_height or y_min < 0 or 
                x_max > image_width or x_max < 0 or
                y_max > image_height or y_max < 0):
                continue

            # calculating the center coordinates
            x_center = x_min + (bounding_box_width / 2)
            y_center = y_min + (bounding_box_height / 2)

            # normalizing the center coordinates and the 
            # bounding box width and heights
            x_center /= image_width
            y_center /= image_height
            bounding_box_width /= image_width
            bounding_box_height /= image_height

            yolo_bounding_boxes.append({
                "class": 0,
                "center_x": x_center,
                "center_y": y_center,
                "width": bounding_box_width,
                "height": bounding_box_height
            })
    
    return yolo_bounding_boxes if yolo_bounding_boxes else None

def validate_yolo_annotation(image_file: str) -> None:

    yolo_annotation_filename = f'{image_file.split('.')[0]}.txt'
    
    try:
        for line in fileinput.input(yolo_annotation_filename, inplace=True, backup='.bak'):

            annotation = line.strip(' ').split()

            if len(annotation) != 5: continue

            try:

                class_id = int(annotation[0])
                center_x = float(annotation[1])
                center_y = float(annotation[2])
                bounding_box_width = float(annotation[3])
                bounding_box_height = float(annotation[4])
            
            except ValueError: continue

            # Check if normalized values are used. Non-normalized annotations cannot be repaired
            if not ((0.0 <= center_x <= 1.0) and 
                    (0.0 <= center_y <= 1.0) and 
                    (0.0 <= bounding_box_width <= 1.0) and 
                    (0.0 <= bounding_box_height <= 1.0)): 
                continue



            if ( (center_x - (bounding_box_width / 2)) < 0 
            or (center_y - (bounding_box_height / 2)) < 0 
            or (center_x + (bounding_box_width / 2)) > 1
            or (center_y + (bounding_box_height / 2)) > 1):
                continue

            sys.stdout.write(line)
    
    except (FileNotFoundError, OSError) as e:
        logger.error(f"Error opening or processing '{yolo_annotation_filename}': {e}\n")

def process_images_and_annotations(images_dir: str, 
                                   labels_dir: str, 
                                   annotation_type: str) -> None:

    # Get the current working directory of the script
    current_working_directory = os.getcwd()

    # Define the output directories for orphaned and unorphaned files
    orphaned_directory = os.path.join(current_working_directory,"orphaned")
    unorphaned_directory = os.path.join(current_working_directory,"unorphaned")
    corrupted_directory = os.path.join(current_working_directory, "corrupted")

    # Ensure the necessary subdirectories exist
    os.makedirs(os.path.join(orphaned_directory,"images"), exist_ok=True)
    os.makedirs(os.path.join(orphaned_directory, "labels"), exist_ok=True)
    os.makedirs(os.path.join(unorphaned_directory, "images"), exist_ok=True)
    os.makedirs(os.path.join(unorphaned_directory, "labels"), exist_ok=True)
    os.makedirs(corrupted_directory, exist_ok=True)

    image_files = [f for f in os.listdir(images_dir) 
                   if f.lower().endswith(('.png','.jpg','.jpeg','.bmp', '.tif', '.tiff', '.webp'))]

    for filename in tqdm(image_files, desc="Processing images and their annotations"):

        image_path = os.path.join(images_dir,filename)
        image = cv2.imread(image_path)

        if image is None:
            logger.warning(f"Warning: Could not open image {filename}. Skipping")

            try:
                shutil.move(image_path, corrupted_directory)
                logger.success(f"Moved corrupted image {filename} to {corrupted_directory}")
            
            except Exception as e:
                logger.error(f"Error moving corrupted image {filename} : {e}")

            continue

        height, width, channels = image.shape
        logger.info(f"Processing '{filename}': width = {width}, height = {height}, channels = {channels}")

        match annotation_type.lower():

            case 'coco':
                
                if not os.path.isfile(labels_dir):
                    # Immediately stop if the COCO annotation file does not exist
                    logger.error(f"Error: COCO annotation file '{labels_dir}' does not exist")
                    return

                image_id = parse_coco_annotation(filename, labels_dir)

                # if no annotation is found the image is considered orphaned
                if image_id is None:
                    logger.info(f"No COCO annotation(s) found for {filename}")
                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        logger.success(f"Moved {image_path} to {os.path.join(orphaned_directory, 'images', filename)}")

                    except Exception as e:
                        logger.error(f"Error moving {filename} : {e}")
                    
                    # skip to the next image
                    continue
 
                yolo_bounding_boxes = validate_coco_annotation(width, height, image_id, labels_dir)

                if yolo_bounding_boxes is None:
                    logger.info(f"No valid bounding boxes for {filename}")
                    
                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        logger.success(f"Moved {image_path} to {os.path.join(orphaned_directory, 'images', filename)}")
                    
                    except Exception as e:
                        logger.error(f"Error moving {filename} : {e}")
                    
                    continue

                try:
                    yolo_text_file = os.path.join(unorphaned_directory, "labels", f"{filename}.txt")

                    with open(yolo_text_file, "w", encoding="utf-8") as f:
                        for bounding_box in yolo_bounding_boxes:
                            class_id = bounding_box['class']
                            center_x = bounding_box['center_x']
                            center_y = bounding_box['center_y']
                            width = bounding_box['width']
                            height = bounding_box['height']
                            f.write(f"{class_id} {center_x} {center_y} {width} {height}\n")

                    shutil.move(image_path, os.path.join(unorphaned_directory, "images", filename))
                    logger.success(f"Moved {image_path} to {os.path.join(unorphaned_directory, 'images',)}")
                    logger.success(f"Created yolo annotation text file {yolo_text_file}")
                except Exception as e:
                    logger.error(f"Error moving {filename} : {e}")
                

            case 'yolo':
                validate_yolo_annotation(filename)
            
            case 'pascal_voc':
                base_name = os.path.splitext(filename)[0]
                xml_file = os.path.join(labels_dir, f"{base_name}.xml")
                bounding_boxes = parse_voc_annotation(xml_file)

                if bounding_boxes is None:
                    logger.info(f"No valid VOC annotation found for {filename}")

                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        logger.success(f"Moved {image_path} to {os.path.join(orphaned_directory, 'images')}")

                        xml_file_path = os.path.join(labels_dir, f"{base_name}.xml")
                        shutil.move(xml_file_path, os.path.join(orphaned_directory, "labels", f"{base_name}.xml"))
                        logger.success(f"Moved {base_name}.xml to {os.path.join(orphaned_directory, 'labels')}")
                    
                    except Exception as e:
                        logger.error(f"Error moving {filename} : {e}")
                    
                    continue
                    
                yolo_bounding_boxes = validate_voc_annotation(width,height,bounding_boxes)
                try:
                    yolo_text_file = os.path.join(unorphaned_directory, "labels", f"{filename}.txt")
                    with open(yolo_text_file, "w", encoding="utf-8") as f:

                        for bounding_box in yolo_bounding_boxes:
                            class_id = bounding_box['class']
                            center_x = bounding_box['center_x']
                            center_y = bounding_box['center_y']
                            width = bounding_box['width']
                            height = bounding_box['height']
                            f.write(f"{class_id} {center_x} {center_y} {width} {height}\n")

                    shutil.move(image_path, os.path.join(unorphaned_directory, 'images', filename))
                    logger.success(f"Moved {image_path} to {os.path.join(unorphaned_directory, 'images')}")
                    logger.success(f"Created yolo annotation text file {yolo_text_file}")
                
                except Exception as e:
                    logger.error(f"Error moving {filename} : {e}")
            
            case "orphaned":
                try:
                    shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                    logger.success(f"Moved {filename} to {os.path.join(orphaned_directory, 'images')}")
                
                except Exception as e:
                    logger.error(f"Error moving {filename} : {e}")

def eleeye_ascii_art():
    print("      @@@@@@@@@@@@@@@  @@     @@@@@@@@@@@@@                                             ")
    print("      @@@@@@@@@@@@@@@  @@     @@@@@@@@@@@@@                                             ")
    print("      @@@@@@@@@@@@@@@ @@@     @@@@@@@@@@@@@                                             ")
    print("      @@@@ @@@@@@@@@@ @@@     @@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       ")
    print("      @@@@@@@@@@@@@@@ @@@     @@@@@@@@@@@      @ _____ _      _______   _______ @       ")
    print("      @@@@@@@@@@@@@@@ @@@@@@  @@@@@@@@@@@      @| ____| | ___| ____\ \ / / ____|@       ")
    print("      @@@@@@@@@@@@@@@         @@@@@@@@@@@      @|  _| | |/ _ \  _|  \ V /|  _|  @       ")
    print("      @@@@@@@@@@@@@@  @@@@@@  @@@@@@           @| |___| |  __/ |___  | | | |___ @       ")
    print("      @@@@@@@@@@      @@@@@   @@@@@@           @|_____|_|\___|_____| |_| |_____|@       ")
    print("      @@@@@      @@    @@@    @@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       ")
    print("      @@@@      @@@@    @@    @@@@@@@@@@@@@                                             ")
    print("      @@@@@    @@@@@    @@    @@@@@@@@@@@@@@                                            ")
    print("       @@@@@@@@@@@@     @@    @@@@@@@@@@@@@                                             ")
    print("       @@@@@@@@@@                                                                       ")

def main() -> None:

    parser = argparse.ArgumentParser()
    parser.add_argument("image_directory", type=str, help="Path to the images directory")
    parser.add_argument("label_directory", type=str, help="Path to the labels directory. For COCO datasets, this is a path to a JSON file")
    parser.add_argument("annotation_type", type=str, 
                        choices=["coco","yolo","pascal_voc","orphaned"], 
                         help="Type of annotations to parse: supported annotations are coco, yolo and pascal_voc. orphaned if no annotations are available")

    args = parser.parse_args()

    image_directory = args.image_directory
    label_directory = args.label_directory
    annotation_type = args.annotation_type.lower()


    # Validating command line arguments
    if not os.path.exists(image_directory):
        print(f"Error: Image directory '{image_directory}' does not exist.")
        return
    
    elif not os.path.exists(label_directory):
        print(f"Error: Label directory '{label_directory}' does not exist.")
        return
    
    elif not annotation_type:
        print(f"No annotation type passed")
        return

    elif annotation_type not in ('coco','yolo','pascal_voc','orphaned'):
        print(f"Unsupported annotation type")
    
    else:
        eleeye_ascii_art()
        process_images_and_annotations(image_directory,label_directory,annotation_type)


if __name__ == "__main__":
    main()    