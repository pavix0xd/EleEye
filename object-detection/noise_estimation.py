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
    M = [[1,-2,1],
         [-2,4,-2],
         [1, -2, 1]]
    
    filtered = convolve2d(image, M, mode='valid')
    sigma = np.sum(np.absolute(filtered)) * math.sqrt(math.pi / 2) / (6 * (W-2) * (H-2))
    return sigma

def filter_noisy_images(source_dir, noisy_dir, threshold=10.0, extensions=None):


    if not extensions:

        extensions = ['.jpg', '.jpeg', '.png', '.tiff', '.bmp', '.webp']
    
    os.makedirs(noisy_dir, exist_ok=True)

    all_files = []

    # Gets all image files for each extension specified in the 
    # extensions list and adds it to an all_files list for processing
    for ext in extensions:

        all_files.extend(list(Path(source_dir).glob(f'*{ext}')))
        all_files.extend(list(Path(source_dir).glob(f'{ext.upper()}')))
    
    stats = {
        'total_processed': 0,
        'noisy_images': 0,
        'skipped_images': 0,
        'noise_levels': {}
    }
    
    for img_path in tqdm(all_files, desc="Estimating noise level of images"):

        try:
            img = cv2.imread(str(img_path), cv2.IMREAD_GRAYSCALE)

            # Attempt to read the image
            if not img:
                stats['skipped_images'] += 1
                continue

            # Estimate the noise of the read image
            noise_level = estimate_noise_std(img)

            if noise_level > threshold:

                dest_path = os.path.join(noisy_dir, img_path.name)
                shutil.move(str(img_path),dest_path)
                stats['noisy_images'] += 1
                print(f"Moved noisy image: {img_path.name} (noise level: {noise_level:.2f})")


        except Exception as e:

            print(f"Error processing {img_path}: {e}")
            stats['skipped_images'] += 1

    return stats

def main():

    # Setting command line arguments
    parser = argparse.ArgumentParser(description='Filter out noisy images from a directory')
    parser.add_argument('source_dir', help='Directory containing images to process')
    parser.add_argument('noisy_dir',help='Directory where noisy images will be moved')
    parser.add_argument('--threshold', type=float, default=10.0,
                        help='Noise threshold (standard deviation)')
    parser.add_argument('--extensions', nargs='+',
                        default=['.jpg', '.jpeg', '.png', '.tiff', '.bmp', '.webp'])
    args = parser.parse_args()

    # Logging the start of the noise estimation and filtering process
    print(f"Processing imges in: {args.source_dir}")
    print(f"Noisy images will be moved to: {args.noisy_dir}")
    print(f"Noise threshold: {args.threshold}")

    # Running the filter
    stats = filter_noisy_images(args.source_dir, args.noisy_dir, args.threshold, args.extensions)

    # Log the summary
    print("\n Processing complete")
    print(f"Total images estimated: {stats['total_processed']}")
    print(f"Noisy images moved: {stats['noisy_images']}")
    print(f"Files skipped due to errors: {stats['skipped_images']}")


if __name__ == "__main__":

    main()