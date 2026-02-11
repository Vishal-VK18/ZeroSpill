"""
YOLOv8 Training Script for Expiry Detection Model
Trains custom object detection model for expiry-related text
"""

from ultralytics import YOLO
import torch
from pathlib import Path
import yaml

def check_gpu():
    """Check if CUDA GPU is available"""
    if torch.cuda.is_available():
        print(f"✓ GPU available: {torch.cuda.get_device_name(0)}")
        print(f"  CUDA version: {torch.version.cuda}")
        return 0  # GPU device ID
    else:
        print("⚠ No GPU detected, training will use CPU (much slower)")
        print("  Consider using Google Colab or Kaggle for free GPU")
        response = input("Continue with CPU? (y/n): ")
        if response.lower() != 'y':
            exit()
        return 'cpu'

def train_model(
    data_yaml='expiry_dataset/data.yaml',
    model_size='n',  # n=nano, s=small, m=medium
    epochs=100,
    imgsz=416,
    batch=16,
    patience=20,
    device=None
):
    """
    Train YOLOv8 model for expiry detection
    
    Args:
        data_yaml: Path to dataset configuration
        model_size: Model size (n/s/m/l/x) - 'n' recommended for mobile
        epochs: Number of training epochs
        imgsz: Input image size (416 or 640)
        batch: Batch size (reduce if out of memory)
        patience: Early stopping patience
        device: GPU device ID or 'cpu'
    """
    
    # Check dataset exists
    data_path = Path(data_yaml)
    if not data_path.exists():
        raise FileNotFoundError(f"Dataset config not found: {data_yaml}")
    
    # Load and verify dataset config
    with open(data_path, 'r') as f:
        data_config = yaml.safe_load(f)
    
    print("\n" + "="*60)
    print("TRAINING CONFIGURATION")
    print("="*60)
    print(f"Model: YOLOv8{model_size}")
    print(f"Dataset: {data_config.get('path', 'N/A')}")
    print(f"Classes: {data_config.get('nc', 'N/A')}")
    print(f"Epochs: {epochs}")
    print(f"Image size: {imgsz}x{imgsz}")
    print(f"Batch size: {batch}")
    print(f"Device: {'GPU' if device == 0 else 'CPU'}")
    print("="*60 + "\n")
    
    # Load pretrained YOLOv8 model
    model_name = f'yolov8{model_size}.pt'
    print(f"Loading pretrained model: {model_name}")
    model = YOLO(model_name)
    
    # Train the model
    print("\nStarting training...")
    print("This may take 2-8 hours depending on your GPU")
    print("Monitor progress in runs/detect/exp_v1/\n")
    
    results = model.train(
        data=data_yaml,
        epochs=epochs,
        imgsz=imgsz,
        batch=batch,
        device=device,
        patience=patience,
        save=True,
        project='runs/detect',
        name='exp_v1',
        exist_ok=True,
        pretrained=True,
        optimizer='AdamW',
        verbose=True,
        seed=42,
        deterministic=True,
        # Data augmentation
        hsv_h=0.015,  # HSV-Hue augmentation
        hsv_s=0.7,    # HSV-Saturation augmentation
        hsv_v=0.4,    # HSV-Value augmentation
        degrees=5.0,  # Rotation
        translate=0.1, # Translation
        scale=0.5,    # Scaling
        shear=0.0,    # Shear
        perspective=0.0, # Perspective
        flipud=0.0,   # Vertical flip
        fliplr=0.5,   # Horizontal flip
        mosaic=1.0,   # Mosaic augmentation
        mixup=0.1,    # Mixup augmentation
        copy_paste=0.0, # Copy-paste augmentation
    )
    
    print("\n" + "="*60)
    print("TRAINING COMPLETE!")
    print("="*60)
    
    # Validate the model
    print("\nValidating model on test set...")
    metrics = model.val()
    
    print("\nValidation Results:")
    print(f"  mAP50: {metrics.box.map50:.4f}")
    print(f"  mAP50-95: {metrics.box.map:.4f}")
    print(f"  Precision: {metrics.box.p:.4f}")
    print(f"  Recall: {metrics.box.r:.4f}")
    
    # Check if model is good enough
    if metrics.box.map50 < 0.75:
        print("\n⚠ WARNING: mAP50 is below 0.75")
        print("  Consider:")
        print("  - Training for more epochs")
        print("  - Adding more training data")
        print("  - Using larger model (yolov8s)")
    else:
        print("\n✓ Model performance looks good!")
    
    print("\n" + "="*60)
    print("NEXT STEPS:")
    print("="*60)
    print("1. Review results in: runs/detect/exp_v1/")
    print("2. Check confusion matrix and validation images")
    print("3. If satisfied, run: python export_to_tflite.py")
    print("="*60)
    
    return model, metrics


if __name__ == '__main__':
    # Check GPU availability
    device = check_gpu()
    
    # Train model
    model, metrics = train_model(
        data_yaml='expiry_dataset/data.yaml',
        model_size='n',  # nano - optimized for mobile
        epochs=100,
        imgsz=416,  # smaller size for mobile
        batch=16,   # adjust based on GPU memory
        patience=20,
        device=device
    )
    
    print("\n✓ Training pipeline complete!")
