# Placeholder TFLite Model File

This is a placeholder file. 

## To get the actual model:

1. Train the model using the scripts in `ml_training/`
2. Run: `python ml_training/export_to_tflite.py`
3. The trained model will be automatically copied here

## Or manually place your trained model:

Place your `expiry_detector.tflite` file in this directory.

Expected file size: 1.5-2 MB (INT8 quantized)

## Training Instructions

See `ml_training/README.md` for complete training guide.

Quick start:
```bash
cd ml_training
pip install -r requirements.txt
python synthetic_dataset_generator.py
python train_expiry_model.py
python export_to_tflite.py
```
