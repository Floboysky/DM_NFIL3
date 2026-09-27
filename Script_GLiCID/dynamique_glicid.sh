#!/bin/bash


#SBATCH --job-name=dynamique                                 # Name for your job
#SBATCH --comment="simulation de dynamique moléculaire"      # Comment for your job
#SBATCH --mail-user=florent.boyer@etu.univ-nantes.fr         # Mail
#SBATCH --mail-type=all

#SBATCH --output=output_dm.out           # Output file
#SBATCH --error=error_dm.err             # Error file

#SBATCH --time=06-00:00:00         # Time limit
#SBATCH --nodes=1                  # How many nodes to run on
#SBATCH --ntasks=1                 # How many tasks per node
#SBATCH --cpus-per-task=48         # Number of CPUs per task
#SBATCH --mem-per-cpu=4g           # Memory per CPU
#SBATCH --qos=long                 # Priority/Quality of service


# Command to run:
module load guix

# Modèle pour la dynamique
dynamique_all="$1"
dynamique=${dynamique_all/%.pdb/}

# Si besoin on supprime toutes les molécules d'eaux et d'ions du modèle
grep -v HETATM $dynamique.pdb > new_$dynamique.pdb

# On convertit le fichier PDB en GMX et on y ajoute un champ de force
gmx pdb2gmx -f new_$dynamique.pdb -o processed_$dynamique.gro -water spce <<< "15"
# 6 = AMBER99SB-ILDN ou 8 = CHARMM27 ou 14 = GROMOS96 54a7 ou 15 = OPLS-AA/L

# Définir l'espace de simulation (cubic/hexagonal/dodecahedron/octahedron)
gmx editconf -f processed_$dynamique.gro -o box_$dynamique.gro -c -d 4.0 -bt dodecahedron

# Rajout du solvant (H2O)
gmx solvate -cp box_$dynamique.gro -cs spc216.gro -o solvate_$dynamique.gro -p topol.top

# Ajout d'ions
gmx grompp -f ions.mdp -c solvate_$dynamique.gro -p topol.top -o ions.tpr
gmx genion -s ions.tpr -o solvate_ions_$dynamique.gro -p topol.top -neutral <<< "13"
# 13 = SOL

# Minimum d'énergie
gmx grompp -f em.mdp -c solvate_ions_$dynamique.gro -p topol.top -o em.tpr
gmx mdrun -v -deffnm em

# Equilibrage thermodynamique
# 1er étape
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gmx mdrun -v -deffnm nvt

# 2e étape
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gmx mdrun -v -deffnm npt

# Simulation
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr
gmx mdrun -v -deffnm md_0_1

echo -e "\ndynamique terminée!"
# Visualiser la simulation avec les fichiers md_0_1.gro et md_0_1.xtc...
