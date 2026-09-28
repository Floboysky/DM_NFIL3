Dépôt GitHub pour l'analyse de la DM d'un peptide avec le domaine WD40 de TBL1R:

## Installation
Dans un terminal Anaconda lancer les lignes de commandes suivantes:

```bash
git clone https://github.com/Floboysky/DM_NFIL3.git
conda env create -f environment.yml
conda activate analyse_md
```

## Description and Usage
- Les scripts servent à lancer la DM dans le serveur GLiCID
Au préalable bien s'assurer d'avoir installer GROMACS et gmx_MMBPSA sur sa session GLiCID (voir doc:[GLiCID](https://doc.glicid.fr/GLiCID-PUBLIC/main/)).
    -`dynamique_glicid.sh`: Lancement de la DM à partir d'un fichier PDB.
    -`energy_binding.sh:` Lance la commande `gmx_MMPBSA` pour le calcul de l'évolution du ΔG.
    -`analyse_md.sh`: Calcul le RMSD, RMSF, Rg, PCA et met tous les fichiers de résultats dans un dossier "Fichiers".

Les scripts .mdp servent aux paramètres de la DM, et le script .in sert au paramètre de l'analyse MM_PBSA.

- Les fichiers Notebook servent à l'analyse des DM
    -`Analyse_MD_traj`: Script qui définit les atomes du ligand et du recepteur, et qui cherche les pseudo-contacts pour chaques atomes du ligand définit avec ses cibles du récepteur elle ausssi bien définit.
    -`Analyse_MD_plot_traj.ipynb`: Script qui plot les graph de densité de contacts et de l'évolution du ΔG.
    -`Analyse_MD_plot.ipynb`: Script qui plot les graph de RMSD, RMSF, Rg, PCA...
