# Single-Molecule TIRF Analysis: Two- and Three-Colour Pipelines

Code for analysing single-molecule TIRF microscopy data from experiments where small heat shock proteins (sHsps) are in complex with a client protein (Fluc). Two experiment types are covered:

- **Two-colour:** client (Fluc) and sHsp imaged in two colour channels.
- **Three-colour:** client (Fluc), sHsp and Hsp70 imaged together in three colour channels.

Both pipelines follow the same overall approach. Per-molecule data (position, colocalisation status, photobleaching trajectory) are extracted in ImageJ/Fiji, then compiled, filtered and cross-referenced in R. Molecule stoichiometry is calculated from photobleaching steps using [py4bleaching](https://github.com/ljr979/py4bleaching) (Rice et al.), and its output is matched back to the per-molecule data in R.

This repository accompanies the thesis of Nicola A

## Contents

- [Requirements](#requirements)
- [Two-colour pipeline](#two-colour-pipeline)
- [Three-colour pipeline](#three-colour-pipeline)
- [Differences between the two pipelines](#differences-between-the-two-pipelines)
- [Notes before running](#notes-before-running)
- [Citation](#citation)
- [License](#license)

## Requirements

**ImageJ/Fiji**, with:
- [MultiStackReg](https://bradbusse.net/sciencedownloads.html) plugin (image alignment)
- "Single Molecule Biophysics" plugin (`s_m_b.jar`), which provides Peak Finder and Beam Profile Correction (included in `utilities/`)
- Custom macro/script files (included in `utilities/`):
  - Both pipelines: `count_colocalized_peaks_Andrew.js`, `Filter_for_colocal.ijm`, `results_to_ROI.txt`, `peak_intensity.txt`, `scramble_xy.js`
  - Two-colour only: `Filter_for_noncolocal_v2.ijm`

**R** (version used: 4.2.2), with packages:
- `tidyverse`
- `tidylog`
- `fs`
- `hexbin`

**Python**, for py4bleaching. See that repository's own requirements.

### py4bleaching

py4bleaching is used as a git submodule:

```bash
cd utilities/pb/
git submodule add https://github.com/ljr979/py4bleaching py4bleaching
```

## Input data

Raw data are not included in this repository (single-molecule TIRF movies; not included on Zenodo due to file size). Raw data are organised as `<vorg_folder>/<treatment>/<replicate>/AF647 photobleach/` for both pipelines. The files expected in that folder differ between pipelines and are listed in the sections below.

---

## Two-colour pipeline

### Pipeline overview

| Step | Tool | Script | Purpose |
|---|---|---|---|
| 1 | ImageJ/Fiji | `Client_Hsp_colocalisation_trajectories_w_scramble_annotated.ijm` | Background-correct and align raw movies, find peaks, identify colocalised/non-colocalised molecules, extract photobleaching trajectories, and generate randomised ("scrambled") coordinates as a colocalisation control |
| 2 | R | `1__compiling_data_and_colocalisation_analysis.R` | Compile all per-image ImageJ results across replicates/treatments, assign a unique molecule ID to each spot, and cross-reference colocalisation (real and scrambled) between the two channels |
| 3 | R | `2__moving_the_trajectory_files_to_local_folder.R` | Copy trajectory CSVs from the raw-data location into a local, per-fluorophore folder structure ready for py4bleaching |
| — | External | [py4bleaching](https://github.com/ljr979/py4bleaching) | Run separately on each fluorophore's trajectories to calculate molecule stoichiometry from photobleaching steps |
| 4 | R | `3__preparing_trajectories_for_py4bleaching.R` | Rename trajectory columns with each molecule's unique ID and X/Y coordinates so py4bleaching output can be traced back to individual molecules |
| 5 | R | `4__matching_R_results_to_py4bleaching_and_trajectory_analysis_graphing.R` | Match py4bleaching's molecule-size output back to the colocalisation data, combine into one results table, and generate summary plots (histograms, boxplots, heatmap of client vs. Hsp stoichiometry) |

Run order: **ImageJ macro → R script 1 → R script 2 → py4bleaching → R script 3 → R script 4**.

### Input data (two-colour)

The ImageJ macro expects, per image/movie: a raw two-channel TIFF, a corresponding `ROI.zip`, a `TransformationMatrices.txt` alignment file, and per-channel background images (`488_background.tif`, `647_background.tif`) in the same folder.

### Expected folder structure (two-colour)

Inside `AF647 photobleach/`:

```
AF647 photobleach/
├── ROI.zip
├── TransformationMatrices.txt
├── 488_background.tif
├── 647_background.tif
├── Channel488 - 500ms1_Seq0001.nd2        (raw multi-image movie)
├── 1/                                      (one folder per image analysed by the macro)
│   ├── Hsp/                                (per-frame aligned image sequence, from registration step)
│   ├── AVG_Client.jpg, Background_Hsp.jpg
│   ├── Client background corrected.tif, Hsp.tif, MAX_Client.tif, MAX_Hsp.tif
│   ├── Colocalization.tiff
│   ├── Client_results.csv, Hsp_results.csv
│   ├── client_colocalisation.csv, client_non-colocalisation.csv, Hsp_non-colocalisation.csv
│   └── client_colocal_traj.csv, client_non-colocal_traj.csv, Hsp_colocal_traj.csv, Hsp_non-colocal_traj.csv
├── 2/ ... 6/                               (same contents as above, one per image)
├── client_results/                         (aggregated, image-prefixed copies across all images)
│   ├── *_client_results.csv
│   ├── *_client_colocalisation.csv
│   ├── *_client_non-colocalisation.csv
│   └── *_scramble_colocalized.csv
├── hsp_results/
│   ├── *_Hsp_results.csv
│   └── *_hsp_non-colocalisation.csv
└── Trajectories/
    ├── Coloc/{Client,Hsp}/
    └── non-coloc/{Client,Hsp}/
```

R script 1 reads from the aggregated `client_results/`/`hsp_results/` folders (not the numbered per-image folders) and prompts interactively (Y/N) for which top-level treatment subfolders to include.

R script 2 reorganises trajectory files into `imagejresults-<fluorophore>/<fluorophore>/<treatment>/<fluorophore-label>/` ready for py4bleaching.

### Outputs (two-colour)

- `full_data/all_clients_results.csv`, `full_data/all_hsp_results.csv`: per-molecule data with colocalisation status (real and scrambled) and unique molecule IDs
- `full_data/client_and_hsp_colocalisation_results.csv`, `full_data/client_non-colocal_results.csv`, `full_data/hsp_non-colocal_results.csv`
- `analysis_outputs/percent_coloc_summary.csv`: per-image colocalisation percentage (real vs. scrambled control)
- `analysis_outputs/full_molecule_results.csv`: final combined table with py4bleaching stoichiometry matched to each molecule, used for the heatmap and histogram plots

---

## Three-colour pipeline

### Channels

| Label | Fluorophore | Role |
|---|---|---|
| Client (Fluc) | 555 | aligned to sHsp reference |
| Hsp70 | 488 | aligned to sHsp reference |
| sHsp | 647 | reference channel (not aligned) |

### Pipeline overview

| Step | Tool | Script | Purpose |
|---|---|---|---|
| 1 | ImageJ/Fiji | `0. Three_colour_Client_Hsp_colocalisation_trajectories_w_scramble_annotated.ijm` | Background-correct and align the client (555) and Hsp70 (488) channels to the sHsp (647) reference, find peaks in all three channels, run pairwise colocalisation (client–sHsp, client–Hsp70, sHsp–Hsp70) plus scrambled-coordinate controls for each pair, and extract a photobleaching trajectory for every molecule in every channel |
| 2 | R | `1. compiling_data_and_colocalisation_analysis.R` | Compile all per-image ImageJ results across replicates/treatments, assign each molecule a unique ID, and cross-reference all three pairwise colocalisations (real and scrambled) for every molecule |
| 3 | R | `2. moving_the_trajectory_files_to_local_folder.R` | Copy trajectory CSVs into a local, per-fluorophore folder structure ready for py4bleaching |
| — | External | [py4bleaching](https://github.com/ljr979/py4bleaching) | Run separately for each fluorophore (555, 647, 488) to calculate molecule stoichiometry from photobleaching steps |
| 4 | R | `3. preparing_trajectories_for_py4bleaching.R` | Rename trajectory columns with each molecule's unique ID and X/Y coordinates, per fluorophore, so py4bleaching output can be traced back to individual molecules |
| 5 | R | `4. matching_R_results_to_py4bleaching_and_trajectory_analysis_graphing.R` | Match py4bleaching's molecule-size output back to each protein's results, build tables of colocalised complexes (client–sHsp, client–Hsp70, sHsp–Hsp70), and generate heatmaps of client/sHsp/Hsp70 stoichiometry for each complex type |

Run order: **ImageJ macro → R script 1 → R script 2 → py4bleaching (×3 fluorophores) → R script 3 → R script 4**.

Trajectories are extracted for **every** detected molecule regardless of colocalisation status (saved to `Trajectories/ALL/`). Colocalisation status against the other two channels is attached as metadata in R script 1, rather than by physically separating files into "coloc"/"non-coloc" folders.

### Input data (three-colour)

The ImageJ macro expects, per image/movie: raw single-channel TIFFs for each of the three fluorophores, a corresponding `ROI_cropped.zip`, two alignment files, and per-channel background images:

- `TransformationMatrices_552_to_647.txt` (client → sHsp reference)
- `TransformationMatrices_488_to_647.txt` (Hsp70 → sHsp reference)
- `555_background.tif`, `647_background.tif`, `488_background.tif`

The macro also references FRET background images (`555_FRET_background.tif`, `488_647_FRET_background.tif`, `488_555_FRET_background.tif`) and creates a `FRET_results/` folder with subfolders for each FRET pair, but no FRET analysis is actually performed by this version of the macro. The folders are created but left unpopulated.

### Expected folder structure (three-colour)

Inside `AF647 photobleach/`:

```
AF647 photobleach/
├── ROI_cropped.zip
├── TransformationMatrices_532_to_647.txt
├── TransformationMatrices_488_to_647.txt
├── 555_background.tif, 647_background.tif, 488_background.tif
├── Client_results.csv, sHsp_results.csv, Hsp70_results.csv
├── client_colocalisation_sHsp.csv, client_colocalisation_Hsp70.csv, sHsp_colocalisation_Hsp70.csv
├── client_results/
│   ├── *_client_results.csv
│   ├── *_client_colocalisation_sHsp.csv
│   ├── *_client_colocalisation_Hsp70.csv
│   ├── *_client_sHsp_scramble_colocalized.csv
│   └── *_client_Hsp70_scramble_colocalized.csv
├── sHsp_results/
│   ├── *_sHsp_results.csv
│   ├── *_sHsp_colocalisation_Hsp70_results.csv
│   └── *_Hsp70_scramble_colocalized.csv
├── Hsp70_results/
│   └── *_Hsp70_results.csv
└── Trajectories/
    └── ALL/{Client,sHsp,Hsp70}/
```

R script 1 reads from the aggregated `client_results/`/`sHsp_results/`/`Hsp70_results/` folders and prompts interactively (Y/N) for which top-level treatment subfolders to include.

### Outputs (three-colour)

- `full_data/all_clients_results_coloc.csv`, `all_sHsp_results_coloc.csv`, `all_Hsp70_results_coloc.csv`: per-molecule data with colocalisation status (real and scrambled) against both other channels, and unique molecule IDs (`C`/`S`/`H` prefixes)
- `analysis_outputs/percent_coloc_summary_client.csv`, `coloc_summary_all_proteins.csv`: per-treatment colocalisation percentages
- `full_data/all_clients_results_coloc_traj.csv`, `all_sHsp_results_coloc_traj.csv`, `all_Hsp70_results_coloc_traj.csv`: with py4bleaching stoichiometry matched in
- `full_data/client_complexes.csv`, `sHsp_Hsp70_complexes.csv`: colocalised-complex tables used for the final heatmaps

---

## Differences between the two pipelines

| | Two-colour | Three-colour |
|---|---|---|
| Channels | Client, sHsp (Hsp) | Client (555), sHsp (647), Hsp70 (488) |
| Colocalisation | Client vs. Hsp | Pairwise: client–sHsp, client–Hsp70, sHsp–Hsp70 |
| Trajectory handling | Separated into `Coloc/` and `non-coloc/` | All molecules in `ALL/`; colocalisation attached as metadata in R |
| ROI file | `ROI.zip` | `ROI_cropped.zip` |
| Alignment | One `TransformationMatrices.txt` | Two files (532→647 and 488→647) |
| Macro re-run behaviour | Re-runs the alignment step | Skips alignment if `Client.tif`/`Hsp70.tif` already exist |
| py4bleaching runs | Per fluorophore | Per fluorophore (555, 647, 488) |
| Script naming | `1__name.R` | `1. name.R` |
| Final plots | Histograms, boxplots, client vs. Hsp heatmap | Heatmaps of client/sHsp/Hsp70 stoichiometry per complex type |

## Notes before running

- **File paths are hard-coded** throughout (e.g. `Z:/Chaperone_subgroup/...`, `C:/Nicola/UNIVERSITY/...`, macro paths under `C:/Nicola/UNIVERSITY/PhD/SM/...`), including the `runMacro("C:/...")` calls in the `.ijm` files. These need to be changed to your own directories before running. Search for `experiment_date`, `vorg_folder`, `local_folder`, and `runMacro`.
- The two-colour ImageJ macro requires manual interaction at two points (peak selection via Peak Finder, confirmed via `waitForUser`).
- The three-colour ImageJ macro skips the alignment step if `Client.tif`/`Hsp70.tif` already exist, which is useful if you are re-running after an interruption. The two-colour macro does not do this.
- Filenames are expected to contain `Channel488...#<n>` for the image-number extraction in R script 1 to work; adjust `process_dfs()` if your naming convention differs.
- Before running py4bleaching on three-colour data, folder names must have underscores removed (per the comment at the end of three-colour R script 3) or py4bleaching will error.

## Citation

This code uses py4bleaching for photobleaching step analysis:

> Rice L, Marzano N, Cox D, Skewes B, van Oijen AM, Ecroyd H (2025). Single-molecule observations of human small heat shock proteins in complex with aggregation-prone client proteins. Biochemical Journal 482: 413-432. doi:10.1042/BCJ20240473

## License

This project is licensed under the MIT License. See the LICENSE file for details.
