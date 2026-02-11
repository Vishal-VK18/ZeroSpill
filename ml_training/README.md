# Expiry Detection Model Training Guide

Complete guide for training a custom YOLOv8 model to detect expiry-related text on grocery packaging.

## Quick Start (Synthetic Dataset - Recommended)

### Step 1: Setup Environment

**Option A: Google Colab (Free GPU - Recommended)**
1. Open [Google Colab](https://colab.research.google.com)
2. Create new notebook
3. Upload all `.py` files from `ml_training/` folder
4. Run setup:
```python
!pip install ultralytics Pillow numpy
from google.colab import drive
drive.mount('/content/drive')
```

**Option B: Local Setup (Requires NVIDIA GPU)**
```bash
# Create virtual environment
python -m venv yolo_env

# Activate environment
# Windows:
yolo_env\Scripts\activate
# Linux/Mac:
source yolo_env/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### Step 2: Generate Synthetic Dataset

```bash
# Generate 500 labeled images (takes ~5-10 minutes)
python synthetic_dataset_generator.py
```

This creates:
- `expiry_dataset/images/train/` - 350 training images
- `expiry_dataset/images/val/` - 100 validation images
- `expiry_dataset/images/test/` - 50 test images
- `expiry_dataset/labels/` - YOLO format annotations
- `expiry_dataset/data.yaml` - Dataset configuration

**Review Generated Data:**
- Open `expiry_dataset/images/train/` and check a few images
- Verify bounding boxes look correct
- If quality is poor, regenerate with different parameters

### Step 3: Train Model

```bash
# Start training (2-8 hours depending on GPU)
python train_expiry_model.py
```

**Training Progress:**
- Monitor in real-time: `runs/detect/exp_v1/`
- Check `results.png` for loss curves
- Check `confusion_matrix.png` for class accuracy
- Tensorboard: `tensorboard --logdir runs/detect`

**Expected Results:**
- mAP50 > 0.85 = Good
- mAP50 > 0.90 = Excellent
- Training time: 2-4 hours (GPU), 20+ hours (CPU)

**If Training Fails:**
- GPU out of memory: Reduce `batch` to 8 or 4
- Poor accuracy: Increase `epochs` to 150-200
- Model not learning: Check dataset quality

### Step 4: Export to TFLite

```bash
# Convert model to TFLite with INT8 quantization
python export_to_tflite.py
```

This will:
1. Load trained model from `runs/detect/exp_v1/weights/best.pt`
2. Export to TFLite format with INT8 quantization
3. Copy to `d:/ZeroSpill/assets/ml/expiry_detector.tflite`
4. Copy labels to `d:/ZeroSpill/assets/ml/labels.txt`

**Expected Output:**
- File: `expiry_detector.tflite` (~1.5-2 MB)
- Ready for Flutter integration

---

## Alternative: Real-World Dataset

For production-quality model, collect real grocery images:

### Data Collection Strategy

**What to Photograph:**
- At least 300-500 different products
- Various categories: boxes, bottles, cans, pouches
- Different lighting: bright, dim, natural, artificial
- Different angles: straight, tilted, close-up, far
- Include challenging cases: reflective surfaces, curved packaging

**Photography Tips:**
- Use smartphone camera
- Focus on expiry label area
- Include full product in frame
- Avoid extreme blur (slight blur is OK)
- Capture in different environments (kitchen, store, warehouse)

### Annotation Process

**Tools:**
- [LabelImg](https://github.com/heartexlabs/labelImg) (Desktop app)
- [CVAT](https://cvat.org) (Web-based)
- [Roboflow](https://roboflow.com) (annotation only - DO NOT use their models)

**Annotation Guidelines:**
1. Draw tight bounding boxes around each text element
2. Label classes:
   - `use_by` - "USE BY", "USE BEFORE"
   - `best_before` - "BEST BEFORE", "BB"
   - `exp` - "EXP", "EXPIRY DATE", "EXPIRES"
   - `mfg` - "MFG", "MANUFACTURED"
   - `pkd` - "PKD", "PACKED DATE"
   - `date_value` - Actual date numbers
3. Export as YOLO format
4. Organize into same structure as synthetic dataset

**Quality Check:**
- Each image should have 2-6 bounding boxes
- Boxes should be tight (minimal padding)
- Include partial text if visible
- Label visible dates even if blurry

### Training with Real Data

```bash
# Same training script works with real data
# Just update data.yaml path if different
python train_expiry_model.py
```

**Fine-tuning from Synthetic:**
If you already trained on synthetic data, you can fine-tune:
```python
# In train_expiry_model.py, change:
model = YOLO('runs/detect/exp_v1/weights/best.pt')  # Use synthetic model
# Then train on real data with lower learning rate
```

---

## Troubleshooting

### GPU Not Detected
```bash
# Check CUDA installation
python -c "import torch; print(torch.cuda.is_available())"

# If False, install CUDA-enabled PyTorch:
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

### Out of Memory Error
Reduce batch size in `train_expiry_model.py`:
```python
batch=8  # or even batch=4
```

### Poor Accuracy (mAP50 < 0.70)
1. Train longer: `epochs=150` or `epochs=200`
2. Use larger model: `model_size='s'` instead of `'n'`
3. Increase dataset: Generate 1000 synthetic images
4. Add real images to synthetic dataset

### Model File Not Found
Check paths:
```bash
ls runs/detect/exp_v1/weights/
```
Should see: `best.pt` and `last.pt`

### Export Fails
Ensure training completed successfully:
- Check for `best.pt` file
- Re-run export with verbose output

---

## Model Performance Benchmarks

**Expected Metrics (Synthetic Dataset):**
| Metric | Good | Excellent |
|--------|------|-----------|
| mAP50 | 0.85+ | 0.92+ |
| mAP50-95 | 0.60+ | 0.75+ |
| Precision | 0.80+ | 0.90+ |
| Recall | 0.75+ | 0.85+ |

**Inference Speed:**
| Device | YOLOv8n | YOLOv8s |
|--------|---------|---------|
| Mobile (Android) | ~50-100ms | ~150-250ms |
| GPU (Desktop) | ~5-10ms | ~10-20ms |

---

## Next Steps After Training

1. ✓ Model trained and exported to TFLite
2. → Integrate into Flutter app (see Flutter integration guide)
3. → Test with real grocery products
4. → Iterate and fine-tune based on real-world performance

---

## Files Overview

```
ml_training/
├── synthetic_dataset_generator.py  # Generate synthetic training data
├── train_expiry_model.py          # YOLOv8 training script
├── export_to_tflite.py            # Convert to TFLite format
├── requirements.txt               # Python dependencies
├── README.md                      # This file
└── expiry_dataset/                # Generated by synthetic script
    ├── images/
    ├── labels/
    ├── data.yaml
    └── labels.txt
```

---

## Support

**Common Questions:**

**Q: How long does training take?**
A: 2-4 hours on modern GPU (RTX 3060+), 20+ hours on CPU

**Q: Can I train on Mac M1/M2?**
A: Yes, but slower. Use Google Colab for better performance.

**Q: What GPU do I need?**
A: Minimum 4GB VRAM. GTX 1060 or better recommended.

**Q: Can I add more classes?**
A: Yes, edit `classes` dict in `synthetic_dataset_generator.py`

**Q: How to improve model accuracy?**
A: Collect real-world data and fine-tune the synthetic model
