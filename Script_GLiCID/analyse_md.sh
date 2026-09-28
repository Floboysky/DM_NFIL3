#!/bin/bash


#SBATCH --job-name=analyse_md                               # Name for your job
#SBATCH --comment="analyse de la trajectoire"               # Comment for your job
#SBATCH --mail-user=florent.boyer@etu.univ-nantes.fr        # Mail
#SBATCH --mail-type=all

#SBATCH --output=output_analyse.out          # Output file
#SBATCH --error=error_analyse.err            # Error file

#SBATCH --time=00-01:00:00        # Time limit
#SBATCH --nodes=1                 # How many nodes to run on
#SBATCH --ntasks=1                # How many tasks per node
#SBATCH --cpus-per-task=32        # Number of CPUs per task
#SBATCH --mem-per-cpu=1g          # Memory per CPU
#SBATCH --qos=quick               # Priority/Quality of service


# Création des fichiers md_0_1.pdb et md_0_1.ndx avec les infos sur les atomes appartenant au MRD et au WD40 
python3 conversion_gro.py

# Command to run:
module load guix

# Conversion des formats de trajectoire
echo -e "1\n0" | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc nojump -center -ur compact
# Pour centrer la protéine (1) et enlever les molécules d'eau/ions (14) ou garder tout le système (0)

# Prends la première image de la trajectoire comme état de référence
gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o frame1.pdb -pbc whole -ur compact -dump 0 <<< "0"
# 0 = System ou 14 = non-water

# Calcul du RMSD par rapport à cette ref
echo -e "4\n4" | gmx rms -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsd_vs_start.xvg
# 4 = Backbone

# Calcul des RMSD seulement pour le peptide ou la proteine et non pour l'ensemble du complexe 
echo -e "0\n0" | gmx rms -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsd_peptide.xvg -n md_0_1.ndx
echo -e "1\n1" | gmx rms -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsd_protein.xvg -n md_0_1.ndx
# 0 = Peptide ou 1 = Proteine ou 2 = Solvent

# Calcul du RMSF par rapport à la ref
gmx rmsf -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsf_per_residue.xvg -ox average.pdb -res <<< "1"
# 1 = Protein (7 = MainChain+H + 8 = SideChain) ou 4 = Backbone

# Calcul du rayon de giration par rapport à la ref
gmx gyrate -s frame1.pdb -f md_0_1_noPBC.xtc -o gyrate.xvg <<< "1"
# 1 = Protein (7 = MainChain+H + 8 = SideChain) ou 4 = Backbone


# Analyse en composante principal d'une trajectoire MD
mkdir COVAR
cd COVAR

# Construction de la matrice de covariance
echo -e "4\n4" | gmx covar -s ../frame1.pdb -f ../md_0_1_noPBC.xtc -o eigenvalues.xvg -v eigenvectors.trr -xpma covar.xpm
# 4 = Backbone

# Identification des mouvements avec seulement le premier vecteur
echo -e "4\n4" | gmx anaeig -s ../frame1.pdb -f ../md_0_1_noPBC.xtc -v eigenvectors.trr -eig eigenvalues.xvg -proj proj_ev1.xvg -extr ev1.pdb -rmsf rmsf_ev1.xvg -filt trajfilt1.pdb -first 1 -last 1
# 4 = Backbone


# Création d'un dossier avec en copie tous les fichiers à télécharger (sauf md_0_1_noPBC.xtc...)
cd ..
mkdir Fichiers
cp COVAR/eigenvalues.xvg COVAR/rmsf_ev1.xvg COVAR/ev1.pdb Fichiers/
cp average.pdb error_dm.err frame1.pdb gyrate.xvg md_0_1.ndx md_0_1.pdb md_0_1.gro mdout.mdp output_dm.out rmsd_peptide.xvg rmsd_protein.xvg rmsd_vs_start.xvg rmsd_vs_average.xvg rmsf_per_residue.xvg RESULTS_gmx_MMPBSA.h5 Fichiers/


echo -e "\nanalyse de la dynamique terminée!"
