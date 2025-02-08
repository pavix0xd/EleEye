import albumentations as A
import cv2


quality_transforms = A.Compose([
    A.OneOf([
        A.ImageCompression(compression_type='jpeg', quality_range=(15,25), p=1.0),
        A.AdditiveNoise(noise_type="beta",p=1.0),
        A.SaltAndPepper(amount=(0.01,0.06), salt_vs_pepper=(0.4,0.6),p=1.0),
        A.GaussNoise(std_range=(0.2,0.44),mean_range=(0,0),per_channel=True,noise_scale_factor=1,p=1.0),
        A.Superpixels(p_replace=(0,0.1),n_segments=(90,100),max_size=100,interpolation=cv2.INTER_NEAREST),
        A.MotionBlur(blur_limit=20),
        A.ISONoise(color_shift=(0.01,0.06),intensity=(0.1,0.7)),
        A.defocus(radius=(3,10),alias_blur=(0.1,0.5),p=1.0),
        A.Blur(blur_limit=(3,10), p=1.0),
        A.ZoomBlur(p=1.0),
        A.ShotNoise(p=1.0)
    ])
])

# defining composite weather / condition transforms before 
# incorperating them into the main transform

warm_dry_transform = A.Compose([
    A.HueSaturationValue(
        hue_shift_limit=(-25,-15),
        sat_shift_limit=(-10,0),
        val_shift_limit=(5,15),
        p=1.0
    ),
    A.RandomBrightnessContrast(
        brightness_limit=(0.0,0.1),
        contrast_limit=(0.0,0.1),
        p=0.5
    )
])

gloomy_transform = A.Compose([
    A.RandomFog(alpha_coef=0.05, fog_coef_range=(0.3,0.5), p=1.0),
    A.RandomBrightnessContrast(
        brightness_limit=(-0.3,-0.1),
        contrast_limit=(-0.2, 0.0),
        p=1.0
    ),
    A.HueSaturationValue(
        hue_shift_limit=(-10,0),
        sat_shift_limit=(-20,-10),
        val_shift_limit=(-10,-5),
        p=1.0
    )
])

condition_transforms = A.Compose([
    A.OneOf([
        A.Spatter(intensity=(0.3,0.6),mode='mud',p=1.0), # Mud augmentation
        A.Spatter(intensity=(0.3,0.6), mode='rain', color=[170,170,210], p=1.0), # raindrops on lense augmentation
        A.RandomRain(slant_range=(-25,25), drop_length=3, blur_value=8, rain_type='drizzle', p=1.0), # drizzle / light rain
        A.RandomRain(slant_range=(-25,25), drop_length=3, blur_value=8, rain_type='heavy', p=1.0),  # Heavy rain
        A.RandomRain(slant_range=(-25,25), drop_length=3, blur_value=8, rain_type='torrential', p=1.0), # Extremely heavy rain
        A.PlanckianJitter(mode="cied", temperature_limit=(3000,7500),p=1.0),
        A.RandomFog(alpha_coef=0.05, fog_coef_range=(0.3,0.5), p=1.0),
        A.glass_blur(p=1.0),
        A.RandomSunFlare(src_radius=300, src_color=(255,244,214), method="physics_based", p=1.0),
        A.HueSaturationValue(hue_shift_limit=(-30,10), sat_shift_limit=(15,30), val_shift_limit=(5,15), p=1.0), # simulates warm conditions 
        A.HueSaturationValue(hue_shift_limit=(-20,-10), sat_shift_limit=(10,20), val_shift_limit=(-30,-10), p=1.0), # Simulates evening conditions
        A.HueSaturationValue(hue_shift_limit=(-10,0), sat_shift_limit=(0,10), val_shift_limit=(10,20), p=1.0), # simulates a morning look
        gloomy_transform,
        warm_dry_transform
    ])
])

# defining composite transformation representing objects
# at various distances

distance_transform = A.Compose([
    A.RandomScale(
        scale_limit=0.5,
        interpolation=cv2.INTER_LINEAR,
        p=1.0
    ),

    A.PadIfNeeded(
        min_height=640,
        min_width=640,
        border_mode=cv2.BORDER_CONSTANT,
        value=0,
        p=1.0
    ),

    A.RandomCrop(
        height=640,
        width=640,
        p=1.0
    )
])

positional_transforms = A.Compose([
    A.HorizontalFlip(p=1.0),
    A.VerticalFlip(p=1.0),
    A.ShiftScaleRotate(p=1.0),
    A.RandomSizedCrop(size=(640,640), p=1.0),
    A.RandomCrop(p=1.0),
    A.Perspective(p=1.0),
    A.D4(p=1.0),
    distance_transform
])

main_pipeline = A.Compose([
    quality_transforms,
    condition_transforms,
    positional_transforms
], bbox_params=A.BboxParams(format="yolo", label_fields=['labels']))