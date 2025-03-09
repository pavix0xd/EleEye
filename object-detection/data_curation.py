import json
import sys
import argparse
import os
import cv2
import shutil
import xml.etree.ElementTree as ET
from tqdm import tqdm
from loguru import logger

def eleeye_ascii_art():
    art = r"""
      @@@@@@@@@@@@@@@  @@     @@@@@@@@@@@@@                                             
      @@@@@@@@@@@@@@@  @@     @@@@@@@@@@@@@                                             
      @@@@@@@@@@@@@@@ @@@     @@@@@@@@@@@@@                                             
      @@@@ @@@@@@@@@@ @@@     @@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       
      @@@@@@@@@@@@@@@ @@@     @@@@@@@@@@@      @ _____ _      _______   _______ @       
      @@@@@@@@@@@@@@@ @@@@@@  @@@@@@@@@@@      @| ____| | ___| ____\ \ / / ____|@       
      @@@@@@@@@@@@@@@         @@@@@@@@@@@      @|  _| | |/ _ \  _|  \ V /|  _|  @       
      @@@@@@@@@@@@@@  @@@@@@  @@@@@@           @| |___| |  __/ |___  | | | |___ @       
      @@@@@@@@@@@@@   @@@@@   @@@@@@           @|_____|_|\___|_____| |_| |_____|@       
      @@@@@      @@    @@@    @@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       
      @@@@      @@@@    @@    @@@@@@@@@@@@@                                             
      @@@@@    @@@@@    @@    @@@@@@@@@@@@@@                                            
       @@@@@@@@@@@@     @@    @@@@@@@@@@@@@                                             
       @@@@@@@@@@                                                                       
    """
    print(art)

def parse_voc_annotation(xml_file: str) -> list[dict[str, any]] | None:
    """
    Tries to parse a Pascal VOC .xml file into bounding boxes. Returns None if:
      - The file is missing or unreadable
      - It has no <object> elements
      - There's a parse error
    """
    try:
        tree = ET.parse(xml_file)
        annotation_element = tree.getroot()
    except (FileNotFoundError, ET.ParseError):
        return None

    object_elements = annotation_element.findall('object')
    if not object_elements:
        return None

    bounding_boxes = []
    for object_element in object_elements:
        bndbox_element = object_element.find('bndbox')
        if bndbox_element is not None:
            xmin = bndbox_element.find('xmin').text
            ymin = bndbox_element.find('ymin').text
            xmax = bndbox_element.find('xmax').text
            ymax = bndbox_element.find('ymax').text
            bounding_boxes.append({
                "xmin": xmin,
                "ymin": ymin,
                "xmax": xmax,
                "ymax": ymax
            })
    return bounding_boxes


def validate_voc_annotation(image_width: int,
                            image_height: int,
                            bounding_boxes: list[dict[str, any]]
                            ) -> list[dict[str, float]] | None:
    """
    Given the image dimensions and a list of Pascal VOC bounding boxes,
    returns YOLO-style bounding boxes if valid, or None if none are valid.
    """
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

        # Check bounding box boundaries
        if (xmin > image_width or xmin < 0 or
            xmax > image_width or xmax < 0 or
            ymin > image_height or ymin < 0 or
            ymax > image_height or ymax < 0):
            continue

        bounding_box_width = xmax - xmin
        bounding_box_height = ymax - ymin

        # Calculate midpoint coordinates
        x_center = xmin + (bounding_box_width / 2)
        y_center = ymin + (bounding_box_height / 2)

        # Normalize
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


def load_coco_data(coco_annotation_file: str):
    """
    Loads a COCO JSON file, returning:
     - image_filename_to_id: dict mapping file_name -> image_id
     - annotations_by_image_id: dict mapping image_id -> list of annotation objects
    """
    try:
        with open(coco_annotation_file, 'r', encoding="utf-8") as f:
            coco_data = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        logger.error(f"Error loading COCO data: {e}")
        return None, None

    image_filename_to_id = {img['file_name']: img['id'] for img in coco_data.get('images', [])}
    annotations_by_image_id = {}
    for ann in coco_data.get('annotations', []):
        image_id = ann.get('image_id')
        if image_id is not None:
            annotations_by_image_id.setdefault(image_id, []).append(ann)

    return image_filename_to_id, annotations_by_image_id


def validate_coco_annotation_preindexed(image_width: int,
                                        image_height: int,
                                        image_id: int,
                                        annotations_by_image_id: dict
                                        ) -> list[dict[str, any]] | None:
    """
    Given a COCO image_id and a dictionary of annotations_by_image_id,
    returns YOLO-style bounding boxes if valid, or None if none are valid.
    """
    annotations = annotations_by_image_id.get(image_id, [])
    yolo_bounding_boxes = []

    for annotation in annotations:
        try:
            bbox = annotation.get('bbox')
            x_min = float(bbox[0])
            y_min = float(bbox[1])
            bounding_box_width = float(bbox[2])
            bounding_box_height = float(bbox[3])
        except (TypeError, IndexError):
            continue

        x_max = x_min + bounding_box_width
        y_max = y_min + bounding_box_height

        # Check boundaries
        if (x_min > image_width or x_min < 0 or
            y_min > image_height or y_min < 0 or
            x_max > image_width or x_max < 0 or
            y_max > image_height or y_max < 0):
            continue

        # Convert to YOLO format
        x_center = x_min + (bounding_box_width / 2)
        y_center = y_min + (bounding_box_height / 2)
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


def validate_yolo_annotation(
    image_path: str,
    labels_dir: str,
    orphaned_dir: str,
    unorphaned_dir: str,
    corrupted_dir: str
) -> None:
    """
    For the given image (image_path), attempts to open the corresponding YOLO label file (in labels_dir).
    - If the label file can't be opened/read, move label + image to 'corrupted'.
    - If it can be read but yields no valid bounding boxes, move label + image to 'orphaned'.
    - If there's at least one valid bounding box, create a new YOLO .txt in 'unorphaned' and
      move the image there as well.

    The idea matches the logic in the Pascal VOC and COCO blocks,
    but consolidated here for YOLO label handling.
    """
    filename = os.path.basename(image_path)
    base_name, _ = os.path.splitext(filename)
    label_filename = f"{base_name}.txt"
    label_path = os.path.join(labels_dir, label_filename)

    # 1) If the label doesn't exist, treat it as orphaned (no annotation).
    if not os.path.exists(label_path):
        logger.info(f"YOLO annotation file missing for {filename}: {label_filename}")
        try:
            shutil.move(image_path, os.path.join(orphaned_dir, "images", filename))
            shutil.move(label_path, os.path.join(orphaned_dir, "labels", label_filename))
            logger.success(f"Moved orphaned image+label -> {orphaned_dir}")
        except FileNotFoundError:
            # label_path might not exist, so only the image is moved
            pass
        except Exception as ex:
            logger.error(f"Error moving orphaned files for {filename}: {ex}")
        return

    # 2) Try to read + parse lines
    try:
        with open(label_path, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except (OSError, FileNotFoundError) as e:
        # If label file is unreadable, treat as "corrupted"
        logger.warning(f"Could not read label file {label_path}: {e}")
        move_label_and_image_to_corrupted(label_path, image_path, corrupted_dir)
        return

    # 3) Validate each line
    valid_lines = []
    for line in lines:
        parts = line.strip().split()
        if len(parts) != 5:
            continue

        try:
            # override the class with 0, but let's parse it to ensure numeric
            _ = float(parts[0])
            cx = float(parts[1])
            cy = float(parts[2])
            w = float(parts[3])
            h = float(parts[4])
        except ValueError:
            continue

        # Check normalization
        if not (0 <= cx <= 1 and 0 <= cy <= 1 and 0 <= w <= 1 and 0 <= h <= 1):
            continue

        # Check bounding box edges
        x_min = cx - (w / 2)
        x_max = cx + (w / 2)
        y_min = cy - (h / 2)
        y_max = cy + (h / 2)
        if x_min < 0 or y_min < 0 or x_max > 1 or y_max > 1:
            continue

        # If valid, override class ID with "0" and store
        valid_lines.append(f"0 {cx} {cy} {w} {h}\n")

    # 4) If no valid lines, treat as orphaned
    if not valid_lines:
        logger.info(f"No valid bounding boxes found in '{label_filename}'. Marking as orphaned.")
        try:
            shutil.move(image_path, os.path.join(orphaned_dir, "images", filename))
            shutil.move(label_path, os.path.join(orphaned_dir, "labels", label_filename))
            logger.success(f"Moved orphaned image+label -> {orphaned_dir}")
        except Exception as ex:
            logger.error(f"Error moving orphaned label '{label_filename}': {ex}")
        return

    # 5) Otherwise, we have at least one valid bounding box => unorphaned
    logger.info(f"Found {len(valid_lines)} valid YOLO lines in '{label_filename}'.")
    unorphaned_label_path = os.path.join(unorphaned_dir, "labels", label_filename)
    try:
        # Write new label file
        os.makedirs(os.path.join(unorphaned_dir, "labels"), exist_ok=True)
        with open(unorphaned_label_path, "w", encoding="utf-8") as out_f:
            for vl in valid_lines:
                out_f.write(vl)

        # Move the image
        shutil.move(image_path, os.path.join(unorphaned_dir, "images", filename))

        # Remove original label file
        os.remove(label_path)

        logger.success(f"Label '{label_filename}' -> {unorphaned_label_path}")
        logger.success(f"Image '{filename}' -> {os.path.join(unorphaned_dir, 'images')}")

    except Exception as ex:
        logger.error(f"Error finalizing unorphaned label '{label_filename}': {ex}")


def move_label_and_image_to_corrupted(label_path: str, image_path: str, corrupted_dir: str) -> None:
    """
    Moves the label file and the corresponding image into the 'corrupted' directory
    (separately into 'labels' and 'images') to mirror the structure of other annotation types.
    """
    base_name = os.path.basename(label_path)
    img_name = os.path.basename(image_path)

    try:
        os.makedirs(os.path.join(corrupted_dir, "labels"), exist_ok=True)
        os.makedirs(os.path.join(corrupted_dir, "images"), exist_ok=True)
    except Exception as e:
        logger.error(f"Error creating corrupted subdirectories: {e}")

    try:
        shutil.move(label_path, os.path.join(corrupted_dir, "labels", base_name))
        logger.success(f"Moved corrupted label '{base_name}' -> {os.path.join(corrupted_dir, 'labels')}")
    except Exception as e:
        logger.error(f"Could not move label '{label_path}' to corrupted: {e}")

    try:
        shutil.move(image_path, os.path.join(corrupted_dir, "images", img_name))
        logger.success(f"Moved corrupted image '{img_name}' -> {os.path.join(corrupted_dir, 'images')}")
    except Exception as e:
        logger.error(f"Could not move image '{image_path}' to corrupted: {e}")


def process_images_and_annotations(images_dir: str, labels_dir: str, annotation_type: str) -> None:
    """
    Main pipeline for iterating over images, verifying them, and categorizing
    labels/images into 'orphaned', 'unorphaned', or 'corrupted' subdirectories.
    """
    current_working_directory = os.getcwd()
    orphaned_directory = os.path.join(current_working_directory, "orphaned")
    unorphaned_directory = os.path.join(current_working_directory, "unorphaned")
    corrupted_directory = os.path.join(current_working_directory, "corrupted")

    # Ensure these dirs exist
    os.makedirs(os.path.join(orphaned_directory, "images"), exist_ok=True)
    os.makedirs(os.path.join(orphaned_directory, "labels"), exist_ok=True)
    os.makedirs(os.path.join(unorphaned_directory, "images"), exist_ok=True)
    os.makedirs(os.path.join(unorphaned_directory, "labels"), exist_ok=True)
    os.makedirs(corrupted_directory, exist_ok=True)

    # Collect image filenames
    image_files = [
        f for f in os.listdir(images_dir)
        if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff', '.webp'))
    ]

    # If COCO, pre-index the JSON file
    if annotation_type.lower() == "coco":
        if not os.path.isfile(labels_dir):
            logger.error(f"Error: COCO annotation file '{labels_dir}' does not exist")
            return
        image_filename_to_id, annotations_by_image_id = load_coco_data(labels_dir)
        if image_filename_to_id is None or annotations_by_image_id is None:
            logger.error("Error indexing COCO data")
            return

    for filename in tqdm(image_files, desc="Processing images and their annotations"):
        image_path = os.path.join(images_dir, filename)

        # Attempt to read the image
        image = cv2.imread(image_path)
        if image is None:
            # Consider the image itself corrupted if it can't be opened
            logger.warning(f"Warning: Could not open image {filename}. Marking as corrupted.")
            try:
                shutil.move(image_path, os.path.join(corrupted_directory, "images", filename))
                logger.success(f"Moved corrupted image '{filename}' -> {corrupted_directory}")
            except Exception as e:
                logger.error(f"Error moving corrupted image '{filename}': {e}")
            continue

        height, width, channels = image.shape
        logger.info(f"Processing '{filename}' -> (width={width}, height={height}, channels={channels})")

        match annotation_type.lower():
            case 'coco':
                # Look up image_id
                image_id = image_filename_to_id.get(filename)
                if image_id is None:
                    logger.info(f"No COCO annotations found for {filename}")
                    # Move to orphaned
                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        logger.success(f"Moved {image_path} to orphaned (no COCO annotation)")
                    except Exception as e:
                        logger.error(f"Error moving {filename} to orphaned: {e}")
                    continue

                yolo_bounding_boxes = validate_coco_annotation_preindexed(
                    width, height, image_id, annotations_by_image_id
                )
                if not yolo_bounding_boxes:
                    # Move to orphaned
                    logger.info(f"No valid bounding boxes for {filename}")
                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        logger.success(f"Moved {image_path} -> orphaned (no valid bboxes)")
                    except Exception as e:
                        logger.error(f"Error moving {filename}: {e}")
                    continue

                # We have valid bounding boxes => create YOLO .txt in unorphaned, move image
                try:
                    yolo_text_file = os.path.join(unorphaned_directory, "labels", f"{filename}.txt")
                    with open(yolo_text_file, "w", encoding="utf-8") as f:
                        for bbox in yolo_bounding_boxes:
                            f.write(f"{bbox['class']} {bbox['center_x']} "
                                    f"{bbox['center_y']} {bbox['width']} {bbox['height']}\n")
                    shutil.move(image_path, os.path.join(unorphaned_directory, "images", filename))
                    logger.success(f"Moved {image_path} -> unorphaned")
                    logger.success(f"Created YOLO annotation -> {yolo_text_file}")
                except Exception as e:
                    logger.error(f"Error creating YOLO annotation for {filename}: {e}")

            case 'yolo':
                # Use the new function that does all label-moving (corrupted/orphaned/unorphaned).
                validate_yolo_annotation(
                    image_path,
                    labels_dir,
                    orphaned_directory,
                    unorphaned_directory,
                    corrupted_directory
                )

            case 'pascal_voc':
                # Pascal VOC logic is in two parts: parse + (if bounding_boxes is None => orphaned, else => unorphaned)
                base_name = os.path.splitext(filename)[0]
                xml_file = os.path.join(labels_dir, f"{base_name}.xml")
                bounding_boxes = parse_voc_annotation(xml_file)
                if bounding_boxes is None:
                    # No valid VOC annotation => move image + label to orphaned
                    logger.info(f"No valid VOC annotation for {filename}")
                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        logger.success(f"Moved {image_path} -> orphaned/images")
                        shutil.move(xml_file, os.path.join(orphaned_directory, "labels", f"{base_name}.xml"))
                        logger.success(f"Moved {base_name}.xml -> orphaned/labels")
                    except Exception as e:
                        logger.error(f"Error moving {filename} or {base_name}.xml: {e}")
                    continue

                # Attempt to validate bounding boxes => YOLO format
                yolo_bounding_boxes = validate_voc_annotation(width, height, bounding_boxes)
                if not yolo_bounding_boxes:
                    # If it returns None or empty, treat as orphaned
                    logger.info(f"No valid bounding boxes for {filename}")
                    try:
                        shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                        shutil.move(xml_file, os.path.join(orphaned_directory, "labels", f"{base_name}.xml"))
                    except Exception as e:
                        logger.error(f"Error moving orphaned {filename}: {e}")
                    continue

                # Otherwise, write to unorphaned .txt and move the image
                try:
                    yolo_text_file = os.path.join(unorphaned_directory, "labels", f"{filename}.txt")
                    with open(yolo_text_file, "w", encoding="utf-8") as f:
                        for box in yolo_bounding_boxes:
                            f.write(f"{box['class']} {box['center_x']} {box['center_y']} "
                                    f"{box['width']} {box['height']}\n")

                    shutil.move(image_path, os.path.join(unorphaned_directory, "images", filename))
                    logger.success(f"Moved {image_path} -> unorphaned/images")
                    logger.success(f"Created YOLO annotation file {yolo_text_file}")
                except Exception as e:
                    logger.error(f"Error processing {filename}: {e}")

            case 'orphaned':
                # If annotation_type=="orphaned", we just move images to orphaned.
                try:
                    shutil.move(image_path, os.path.join(orphaned_directory, "images", filename))
                    logger.success(f"Moved {filename} -> orphaned/images")
                except Exception as e:
                    logger.error(f"Error moving {filename}: {e}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("image_directory", type=str, help="Path to the images directory")
    parser.add_argument(
        "label_directory", type=str, nargs="?",
        help="Path to the labels directory (or COCO JSON). If annotation_type is 'orphaned', this is optional."
    )
    parser.add_argument("annotation_type", type=str,
                        choices=["coco", "yolo", "pascal_voc", "orphaned"],
                        help="Type of annotations: 'coco', 'yolo', 'pascal_voc', or 'orphaned' if no annotations.")
    args = parser.parse_args()

    image_directory = args.image_directory
    annotation_type = args.annotation_type.lower()

    if not os.path.exists(image_directory):
        print(f"Error: Image directory '{image_directory}' does not exist.")
        return

    if annotation_type != "orphaned":
        label_directory = args.label_directory
        if not label_directory or not os.path.exists(label_directory):
            print(f"Error: Label directory '{label_directory}' does not exist.")
            return
    else:
        label_directory = None

    eleeye_ascii_art()
    process_images_and_annotations(image_directory, label_directory, annotation_type)


if __name__ == "__main__":
    main()