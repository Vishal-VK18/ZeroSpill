"""
Export Trained YOLOv8 Model to TensorFlow Lite
Converts model for mobile deployment with INT8 quantization
"""

from ultralytics import YOLO
from pathlib import Path
import shutil

def export_to_tflite(
    model_path='runs/detect/exp_v1/weights/best.pt',
    output_name='expiry_detector',
    imgsz=416,
    int8=True,
    data_yaml='expiry_dataset/data.yaml'
):
    """
    Export trained YOLOv8 model to TFLite format
    
    Args:
        model_path: Path to trained PyTorch model
        output_name: Output filename (without extension)
        imgsz: Input image size
        int8: Whether to apply INT8 quantization
        data_yaml: Dataset config (used for quantization calibration)
    """
    
    model_path = Path(model_path)
    if not model_path.exists():
        raise FileNotFoundError(f"Model not found: {model_path}")
    
    print("="*60)
    print("EXPORTING MODEL TO TFLITE")
    print("="*60)
    print(f"Input model: {model_path}")
    print(f"Image size: {imgsz}x{imgsz}")
    print(f"INT8 quantization: {'Yes' if int8 else 'No'}")
    print("="*60 + "\n")
    
    # Load trained model
    print("Loading trained model...")
    model = YOLO(model_path)
    
    # Export to TFLite
    print("\nExporting to TensorFlow Lite...")
    print("This may take 2-5 minutes...\n")
    
    if int8:
        # Export with INT8 quantization
        export_result = model.export(
            format='tflite',
            imgsz=imgsz,
            int8=True,
            data=data_yaml  # Required for quantization calibration
        )
    else:
        # Export without quantization
        export_result = model.export(
            format='tflite',
            imgsz=imgsz,
            int8=False
        )
    
    print("\n✓ Export complete!")
    
    # Find exported TFLite file
    # YOLOv8 exports to best_saved_model/best_[int8/float16].tflite
    model_dir = model_path.parent.parent  # Go up to exp_v1 directory
    saved_model_dir = model_dir / f'{model_path.stem}_saved_model'
    
    # Find the tflite file
    tflite_files = list(saved_model_dir.glob('*.tflite'))
    
    if not tflite_files:
        print("\n⚠ Could not find exported .tflite file")
        print(f"Check directory: {saved_model_dir}")
        return
    
    tflite_path = tflite_files[0]
    file_size_mb = tflite_path.stat().st_size / (1024 * 1024)
    
    print(f"\nExported model: {tflite_path}")
    print(f"File size: {file_size_mb:.2f} MB")
    
    # Copy to Flutter assets
    flutter_assets_dir = Path('d:/ZeroSpill/assets/ml')
    flutter_assets_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy TFLite model
    flutter_model_path = flutter_assets_dir / f'{output_name}.tflite'
    shutil.copy(tflite_path, flutter_model_path)
    print(f"\n✓ Copied to Flutter assets: {flutter_model_path}")
    
    # Copy labels file
    labels_src = Path('expiry_dataset/labels.txt')
    if labels_src.exists():
        labels_dst = flutter_assets_dir / 'labels.txt'
        shutil.copy(labels_src, labels_dst)
        print(f"✓ Copied labels file: {labels_dst}")
    
    print("\n" + "="*60)
    print("TFLITE EXPORT COMPLETE!")
    print("="*60)
    print(f"Model ready for Flutter integration")
    print(f"Size: {file_size_mb:.2f} MB")
    print("\nExpected file sizes:")
    print(f"  INT8 quantized: ~1.5-2 MB {'✓' if int8 and file_size_mb < 3 else ''}")
    print(f"  Float16: ~3-4 MB {'✓' if not int8 and file_size_mb < 5 else ''}")
    
    print("\n" + "="*60)
    print("NEXT STEPS:")
    print("="*60)
    print("1. Verify model in: d:/ZeroSpill/assets/ml/")
    print("2. Update pubspec.yaml with asset path")
    print("3. Integrate model in Flutter code")
    print("4. Test with real device")
    print("="*60)
    
    return flutter_model_path


if __name__ == '__main__':
    # Export trained model
    tflite_path = export_to_tflite(
        model_path='runs/detect/exp_v1/weights/best.pt',
        output_name='expiry_detector',
        imgsz=416,
        int8=True,  # Apply INT8 quantization for smaller size
        data_yaml='expiry_dataset/data.yaml'
    )
    
    print("\n✓ TFLite conversion complete!")
