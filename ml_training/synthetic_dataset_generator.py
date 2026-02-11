"""
Synthetic Expiry Label Dataset Generator
Generates realistic expiry labels with automatic YOLO annotations
For quick-start model training without manual data collection
"""

import os
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import numpy as np
from pathlib import Path

class ExpiryDatasetGenerator:
    def __init__(self, output_dir='expiry_dataset', num_images=500):
        self.output_dir = Path(output_dir)
        self.num_images = num_images
        
        # Class definitions (matching YOLO format)
        self.classes = {
            0: 'use_by',
            1: 'best_before',
            2: 'exp',
            3: 'mfg',
            4: 'pkd',
            5: 'date_value'
        }
        
        # Text variations for each class
        self.text_variants = {
            'use_by': ['USE BY', 'USE BEFORE', 'USE BY:', 'USE-BY'],
            'best_before': ['BEST BEFORE', 'BEST BEFORE:', 'BB', 'BEST-BEFORE'],
            'exp': ['EXP', 'EXPIRY', 'EXPIRY DATE', 'EXP:', 'EXPIRES'],
            'mfg': ['MFG', 'MFG DATE', 'MANUFACTURED', 'MFG:', 'MFD'],
            'pkd': ['PKD', 'PACKED DATE', 'PKD ON', 'PACKED', 'PKD:'],
        }
        
        # Colors for realistic packaging
        self.bg_colors = [
            (255, 255, 255),  # White
            (240, 240, 240),  # Light gray
            (255, 250, 205),  # Light yellow
            (230, 230, 250),  # Lavender
            (245, 222, 179),  # Wheat
            (220, 220, 220),  # Gray
        ]
        
        self.text_colors = [
            (0, 0, 0),        # Black
            (50, 50, 50),     # Dark gray
            (139, 0, 0),      # Dark red
            (0, 0, 139),      # Dark blue
        ]
        
        # Setup directories
        self._setup_directories()
        
    def _setup_directories(self):
        """Create directory structure for YOLO dataset"""
        splits = ['train', 'val', 'test']
        for split in splits:
            (self.output_dir / 'images' / split).mkdir(parents=True, exist_ok=True)
            (self.output_dir / 'labels' / split).mkdir(parents=True, exist_ok=True)
    
    def _get_random_date(self):
        """Generate random date in various formats"""
        formats = [
            lambda: f"{random.randint(1, 28):02d}/{random.randint(1, 12):02d}/{random.randint(2024, 2027)}",
            lambda: f"{random.randint(1, 12):02d}-{random.randint(2024, 2027)}",
            lambda: f"{random.randint(1, 28):02d}.{random.randint(1, 12):02d}.{random.randint(24, 27)}",
            lambda: f"{random.randint(1, 28):02d} {random.choice(['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'])} {random.randint(2024, 2027)}",
        ]
        return random.choice(formats)()
    
    def _get_font(self, size):
        """Try to get a random font, fallback to default"""
        try:
            # Common fonts that might be available
            fonts = [
                'arial.ttf',
                'arialbd.ttf',
                'verdana.ttf',
                'verdanab.ttf',
                'times.ttf',
                'timesbd.ttf',
                'cour.ttf',
                'courbd.ttf',
            ]
            # Windows fonts location
            font_path = f"C:/Windows/Fonts/{random.choice(fonts)}"
            if os.path.exists(font_path):
                return ImageFont.truetype(font_path, size)
        except:
            pass
        
        # Fallback to default
        return ImageFont.load_default()
    
    def _apply_augmentations(self, img):
        """Apply random augmentations to make image more realistic"""
        # Random brightness
        if random.random() > 0.5:
            enhancer = ImageEnhance.Brightness(img)
            img = enhancer.enhance(random.uniform(0.7, 1.3))
        
        # Random contrast
        if random.random() > 0.5:
            enhancer = ImageEnhance.Contrast(img)
            img = enhancer.enhance(random.uniform(0.8, 1.5))
        
        # Random blur
        if random.random() > 0.6:
            img = img.filter(ImageFilter.GaussianBlur(radius=random.uniform(0.5, 1.5)))
        
        # Random rotation
        if random.random() > 0.7:
            img = img.rotate(random.uniform(-5, 5), expand=False, fillcolor=(255, 255, 255))
        
        # Random noise
        if random.random() > 0.7:
            np_img = np.array(img)
            noise = np.random.randint(-20, 20, np_img.shape, dtype=np.int16)
            np_img = np.clip(np_img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
            img = Image.fromarray(np_img)
        
        return img
    
    def _draw_text_with_bbox(self, draw, text, position, font, color):
        """Draw text and return bounding box coordinates"""
        # Get text bounding box
        bbox = draw.textbbox(position, text, font=font)
        
        # Draw slight background for better visibility (optional)
        if random.random() > 0.7:
            padding = 5
            bg_bbox = (bbox[0]-padding, bbox[1]-padding, bbox[2]+padding, bbox[3]+padding)
            draw.rectangle(bg_bbox, fill=(255, 255, 255, 200))
        
        # Draw text
        draw.text(position, text, fill=color, font=font)
        
        return bbox
    
    def _bbox_to_yolo(self, bbox, img_width, img_height):
        """Convert PIL bounding box to YOLO format (normalized)"""
        x_min, y_min, x_max, y_max = bbox
        
        # Calculate center, width, height
        x_center = ((x_min + x_max) / 2) / img_width
        y_center = ((y_min + y_max) / 2) / img_height
        width = (x_max - x_min) / img_width
        height = (y_max - y_min) / img_height
        
        return x_center, y_center, width, height
    
    def generate_image(self):
        """Generate a single synthetic image with expiry labels"""
        # Image dimensions
        img_width = random.randint(800, 1200)
        img_height = random.randint(600, 1000)
        
        # Create image with random background
        bg_color = random.choice(self.bg_colors)
        img = Image.new('RGB', (img_width, img_height), bg_color)
        draw = ImageDraw.Draw(img)
        
        annotations = []  # Store YOLO annotations
        
        # Decide how many label groups to add (1-3)
        num_groups = random.randint(1, 3)
        
        for _ in range(num_groups):
            # Choose keyword type
            keyword_class = random.choice(list(self.text_variants.keys()))
            keyword_text = random.choice(self.text_variants[keyword_class])
            keyword_class_id = list(self.classes.keys())[list(self.classes.values()).index(keyword_class)]
            
            # Generate date
            date_text = self._get_random_date()
            
            # Random position
            x = random.randint(50, img_width - 400)
            y = random.randint(50, img_height - 200)
            
            # Random font sizes
            keyword_size = random.randint(20, 40)
            date_size = random.randint(18, 35)
            
            keyword_font = self._get_font(keyword_size)
            date_font = self._get_font(date_size)
            
            text_color = random.choice(self.text_colors)
            
            # Draw keyword and get bbox
            keyword_bbox = self._draw_text_with_bbox(draw, keyword_text, (x, y), keyword_font, text_color)
            
            # Convert to YOLO format
            yolo_bbox = self._bbox_to_yolo(keyword_bbox, img_width, img_height)
            annotations.append(f"{keyword_class_id} {yolo_bbox[0]:.6f} {yolo_bbox[1]:.6f} {yolo_bbox[2]:.6f} {yolo_bbox[3]:.6f}")
            
            # Draw date below or beside keyword
            if random.random() > 0.5:
                # Below
                date_y = y + keyword_size + random.randint(5, 15)
                date_x = x + random.randint(-20, 20)
            else:
                # Beside
                date_x = x + keyword_bbox[2] - keyword_bbox[0] + random.randint(10, 30)
                date_y = y + random.randint(-5, 5)
            
            date_bbox = self._draw_text_with_bbox(draw, date_text, (date_x, date_y), date_font, text_color)
            
            # Convert to YOLO format for date
            yolo_date_bbox = self._bbox_to_yolo(date_bbox, img_width, img_height)
            annotations.append(f"5 {yolo_date_bbox[0]:.6f} {yolo_date_bbox[1]:.6f} {yolo_date_bbox[2]:.6f} {yolo_date_bbox[3]:.6f}")
        
        # Apply augmentations
        img = self._apply_augmentations(img)
        
        return img, annotations
    
    def generate_dataset(self):
        """Generate complete dataset with train/val/test splits"""
        print(f"Generating {self.num_images} synthetic images...")
        
        # Split ratios
        train_ratio = 0.7
        val_ratio = 0.2
        # test_ratio = 0.1 (remaining)
        
        train_count = int(self.num_images * train_ratio)
        val_count = int(self.num_images * val_ratio)
        
        for i in range(self.num_images):
            # Determine split
            if i < train_count:
                split = 'train'
            elif i < train_count + val_count:
                split = 'val'
            else:
                split = 'test'
            
            # Generate image and annotations
            img, annotations = self.generate_image()
            
            # Save image
            img_filename = f"expiry_{i:04d}.jpg"
            img_path = self.output_dir / 'images' / split / img_filename
            img.save(img_path, quality=85)
            
            # Save annotations
            label_filename = f"expiry_{i:04d}.txt"
            label_path = self.output_dir / 'labels' / split / label_filename
            with open(label_path, 'w') as f:
                f.write('\n'.join(annotations))
            
            if (i + 1) % 50 == 0:
                print(f"Generated {i + 1}/{self.num_images} images...")
        
        print(f"✓ Dataset generation complete!")
        print(f"  Train: {train_count} images")
        print(f"  Val: {val_count} images")
        print(f"  Test: {self.num_images - train_count - val_count} images")
        
        # Create data.yaml
        self._create_data_yaml()
    
    def _create_data_yaml(self):
        """Create YOLO data configuration file"""
        yaml_content = f"""# Expiry Detection Dataset Configuration
path: {self.output_dir.absolute().as_posix()}
train: images/train
val: images/val
test: images/test

# Number of classes
nc: 6

# Class names
names:
  0: use_by
  1: best_before
  2: exp
  3: mfg
  4: pkd
  5: date_value
"""
        yaml_path = self.output_dir / 'data.yaml'
        with open(yaml_path, 'w') as f:
            f.write(yaml_content)
        
        print(f"✓ Created {yaml_path}")
        
        # Also create labels.txt for Flutter
        labels_content = '\n'.join([self.classes[i] for i in range(len(self.classes))])
        labels_path = self.output_dir / 'labels.txt'
        with open(labels_path, 'w') as f:
            f.write(labels_content)
        
        print(f"✓ Created {labels_path}")


if __name__ == '__main__':
    # Generate dataset
    generator = ExpiryDatasetGenerator(
        output_dir='expiry_dataset',
        num_images=500
    )
    generator.generate_dataset()
    
    print("\n" + "="*50)
    print("NEXT STEPS:")
    print("="*50)
    print("1. Review generated images in expiry_dataset/images/")
    print("2. Update data.yaml path if needed")
    print("3. Run training script: python train_expiry_model.py")
    print("="*50)
