GitHub repository for analyzing the structure of a peptide with the WD40 domain of TBL1R:

## Installation
In an Anaconda terminal, run the following command lines:

```bash
git clone https://github.com/Floboysky/DM_NFIL3.git
conda env create -f environment.yml
conda activate analyse_md
```

## Description and Usage
First, make sure you have installed GROMACS and gmx_MMBPSA on your GLiCID session (see documentation: [GLiCID](https://doc.glicid.fr/GLiCID-PUBLIC/main/)).
- The scripts in "Script_GLiCID" are used to launch the DM on the GLiCID server:
    - `dynamique_glicid.sh`: Runs the DM from a PDB file.
    - `energy_binding.sh:` Runs the `gmx_MMPBSA` command to calculate the change in ΔG.
    - `analyse_md.sh`: Calculates the RMSD, RMSF, Rg, and PCA, and places all the result files in a folder named "Fichier".

.mdp scripts are used for DM settings, and the .in script is used for the MM_PBSA analysis settings.

- Notebook files are used for analyzing homework assignments
    - `Analyse_MD_traj`: A script that defines the atoms of the ligand and the receptor, and searches for pseudo-contacts between each defined ligand atom and its corresponding receptor targets.
    - `Analyse_MD_plot_traj.ipynb`: Script that plots the contact density and ΔG evolution graphs.
    - `Analyse_MD_plot.ipynb`: Script that plots graphs of RMSD, RMSF, Rg, PCA...
