import numpy as np
import os
from scipy.signal import convolve2d
from pathlib import Path
from tqdm import tqdm
import argparse
import math
import cv2
import shutil

def estimate_noise_std(image) -> float:
    H, W = image.shape
    M = [[1, -2, 1],
         [-2, 4, -2],
         [1, -2, 1]]
    
    filtered = convolve2d(image, M, mode='valid')
    sigma = np.sum(np.absolute(filtered)) * math.sqrt(math.pi / 2) / (6 * (W - 2) * (H - 2))
    return sigma

def filter_noisy_images(source_img_dir, dest_img_dir, threshold=10.0, extensions=None, label_dir=None, dest_label_dir=None):
    """
    Processes all images in source_img_dir. If an image's estimated noise is above the threshold,
    the image is moved to dest_img_dir.
    
    If label_dir and dest_label_dir are provided, a matching label file (base name with .txt extension)
    will also be moved.
    """
    if not extensions:
        extensions = ['.jpg', '.jpeg', '.png', '.tiff', '.bmp', '.webp']
    
    os.makedirs(dest_img_dir, exist_ok=True)
    if label_dir and dest_label_dir:
        os.makedirs(dest_label_dir, exist_ok=True)

    all_files = []
    for ext in extensions:
        all_files.extend(list(Path(source_img_dir).glob(f'*{ext}')))
        all_files.extend(list(Path(source_img_dir).glob(f'*{ext.upper()}')))

    stats = {
        'total_processed': 0,
        'noisy_images': 0,
        'skipped_images': 0
    }
    
    for img_path in tqdm(all_files, desc=f"Processing images in {source_img_dir}"):
        try:
            img = cv2.imread(str(img_path), cv2.IMREAD_GRAYSCALE)
            if img is None:
                stats['skipped_images'] += 1
                continue

            stats['total_processed'] += 1
            noise_level = estimate_noise_std(img)

            if noise_level > threshold:
                # Move the image to the destination directory
                dest_path = os.path.join(dest_img_dir, img_path.name)
                shutil.move(str(img_path), dest_path)
                stats['noisy_images'] += 1
                print(f"Moved noisy image: {img_path.name} (noise level: {noise_level:.2f})")

                # If label directories are provided, move the matching label file too
                if label_dir and dest_label_dir:
                    base = os.path.splitext(img_path.name)[0]
                    label_file = base + ".txt"
                    src_label_path = os.path.join(label_dir, label_file)
                    if os.path.exists(src_label_path):
                        dest_label_path = os.path.join(dest_label_dir, label_file)
                        shutil.move(src_label_path, dest_label_path)
                        print(f"Moved label: {label_file}")
        except Exception as e:
            print(f"Error processing {img_path}: {e}")
            stats['skipped_images'] += 1

    return stats

def main():
    parser = argparse.ArgumentParser(
        description='Filter out noisy images from orphaned and unorphaned directories and move them to a noisy directory.'
    )
    parser.add_argument('--orphaned', required=True,
                        help='Path to the orphaned base directory (expects an "images" subfolder).')
    parser.add_argument('--unorphaned', required=True,
                        help='Path to the unorphaned base directory (expects "images" and "labels" subfolders).')
    parser.add_argument('--noisy', required=True,
                        help='Path to the destination base directory for noisy images.')
    parser.add_argument('--threshold', type=float, default=10.0,
                        help='Noise threshold (standard deviation).')
    parser.add_argument('--extensions', nargs='+',
                        default=['.jpg', '.jpeg', '.png', '.tiff', '.bmp', '.webp'],
                        help='List of image file extensions to process.')
    args = parser.parse_args()

    # Define source and destination directories for orphaned
    orphaned_img_dir = os.path.join(args.orphaned, "images")
    orphaned_dest_img_dir = os.path.join(args.noisy, "orphaned", "images")
    
    print("\nProcessing orphaned images...")
    orphaned_stats = filter_noisy_images(
        source_img_dir=orphaned_img_dir,
        dest_img_dir=orphaned_dest_img_dir,
        threshold=args.threshold,
        extensions=args.extensions
        # No labels to move for orphaned
    )

    # Define source and destination directories for unorphaned
    unorphaned_img_dir = os.path.join(args.unorphaned, "images")
    unorphaned_label_dir = os.path.join(args.unorphaned, "labels")
    unorphaned_dest_img_dir = os.path.join(args.noisy, "unorphaned", "images")
    unorphaned_dest_label_dir = os.path.join(args.noisy, "unorphaned", "labels")
    
    print("\nProcessing unorphaned images (and labels)...")
    unorphaned_stats = filter_noisy_images(
        source_img_dir=unorphaned_img_dir,
        dest_img_dir=unorphaned_dest_img_dir,
        threshold=args.threshold,
        extensions=args.extensions,
        label_dir=unorphaned_label_dir,
        dest_label_dir=unorphaned_dest_label_dir
    )

    # Summary logging
    print("\n--- Processing Summary ---")
    print("Orphaned:")
    print(f"  Total images processed: {orphaned_stats['total_processed']}")
    print(f"  Noisy images moved: {orphaned_stats['noisy_images']}")
    print(f"  Files skipped: {orphaned_stats['skipped_images']}")

    print("\nUnorphaned:")
    print(f"  Total images processed: {unorphaned_stats['total_processed']}")
    print(f"  Noisy images moved: {unorphaned_stats['noisy_images']}")
    print(f"  Files skipped: {unorphaned_stats['skipped_images']}")

if __name__ == "__main__":
    main()