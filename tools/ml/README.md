# NoriGo ML Tools

## Call Bell Classifier

`train_call_bell_classifier.py` trains a small mobile-friendly binary image
classifier for Culture Scan:

```text
0 -> not_restaurant_call_bell
1 -> restaurant_call_bell
```

`ml_data/` is local training data only. It is intentionally ignored by Git and
is not bundled into the Flutter app. Do not add `ml_data/`, `train/`, `val/`, or
`test/` to `pubspec.yaml`.

The generated TensorFlow Lite model must be compatible with ML Kit custom image
labeling. Keep these labels in this exact order:

```text
not_restaurant_call_bell
restaurant_call_bell
```

If ML Kit does not return label text because the model lacks metadata, the app
maps label index manually:

```text
0 -> not_restaurant_call_bell
1 -> restaurant_call_bell
```

Train from the project root:

```powershell
python tools/ml/train_call_bell_classifier.py
```

Outputs:

```text
build/ml/call_bell_labeler.tflite
build/ml/call_bell_labels.txt
build/ml/call_bell_metrics.json
```

Store dataset backups in Google Drive or external storage. The test split must
be real photos only, not screenshots, mockups, or generated images.

Only these runtime files belong in Flutter assets:

```text
assets/ml/call_bell_labeler.tflite
assets/ml/call_bell_labels.txt
```

Copy the trained model into the Flutter assets folder only after it is real:

```powershell
Copy-Item build/ml/call_bell_labeler.tflite assets/ml/call_bell_labeler.tflite
Copy-Item build/ml/call_bell_labels.txt assets/ml/call_bell_labels.txt -Force
```

Do not commit placeholder `.tflite` files. If the model asset is missing, the
app skips the custom call bell classifier and continues through the existing
base classifier/manual selection flow.

Check that datasets are not bundled:

```powershell
python tools/ml/check_dataset_not_bundled.py
```
