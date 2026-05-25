# Data

This folder contains the open-data package used by the Chinese textbook examples.

- `processed/` contains cleaned CSV files ready for chapter R/Python scripts.
- `processed_manifest.csv` lists files, row counts, columns, and sizes.
- `data_license_inventory.csv` records source and license/attribution notes.
- `chapter_dataset_map.csv` maps chapters to candidate teaching datasets.

The next step is to move chapter-specific datasets into each chapter folder, or update scripts to read from `../../data/processed/`.
