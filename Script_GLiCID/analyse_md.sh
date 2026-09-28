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


# Creation of the md_0_1.pdb and md_0_1.ndx files containing information about the atoms belonging to the ligand and the receptor 
python3 conversion_gro.py

# Command to run:
module load guix

# Conversion of trajectory formats
echo -e "1\n0" | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc nojump -center -ur compact
# To center the protein (1) and remove water molecules/ions (14), or to keep the entire system (0)

# Use the first image of the trajectory as the reference state
gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o frame1.pdb -pbc whole -ur compact -dump 0 <<< "0"
# 0 = System or 14 = non-water

# Calculation of the RMSD relative to this reference
echo -e "4\n4" | gmx rms -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsd_vs_start.xvg
# 4 = Backbone

# Calculation of RMSD values only for the ligand or the receptor, and not for the entire complex
echo -e "0\n0" | gmx rms -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsd_peptide.xvg -n md_0_1.ndx
echo -e "1\n1" | gmx rms -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsd_protein.xvg -n md_0_1.ndx
# 0 = Peptide or 1 = Protein or 2 = Solvent

# Calculation of RMSF relative to the reference
gmx rmsf -s frame1.pdb -f md_0_1_noPBC.xtc -o rmsf_per_residue.xvg -ox average.pdb -res <<< "1"
# 1 = Protein (7 = MainChain+H + 8 = SideChain) or 4 = Backbone

# Calculation of the radius of gyration relative to the reference
gmx gyrate -s frame1.pdb -f md_0_1_noPBC.xtc -o gyrate.xvg <<< "1"
# 1 = Protein (7 = MainChain+H + 8 = SideChain) or 4 = Backbone


# Analyse in principal component of a MD trajectory
mkdir COVAR
cd COVAR

# Construction of the covariance matrix
echo -e "4\n4" | gmx covar -s ../frame1.pdb -f ../md_0_1_noPBC.xtc -o eigenvalues.xvg -v eigenvectors.trr -xpma covar.xpm
# 4 = Backbone

# Identifying movements using only the first vector
echo -e "4\n4" | gmx anaeig -s ../frame1.pdb -f ../md_0_1_noPBC.xtc -v eigenvectors.trr -eig eigenvalues.xvg -proj proj_ev1.xvg -extr ev1.pdb -rmsf rmsf_ev1.xvg -filt trajfilt1.pdb -first 1 -last 1
# 4 = Backbone


# Create a folder containing copies of all the files to be downloaded (except md_0_1_noPBC.xtc)
cd ..
mkdir Fichiers
cp COVAR/eigenvalues.xvg COVAR/rmsf_ev1.xvg COVAR/ev1.pdb Fichiers/
cp average.pdb error_dm.err frame1.pdb gyrate.xvg md_0_1.ndx md_0_1.pdb md_0_1.gro mdout.mdp output_dm.out rmsd_peptide.xvg rmsd_protein.xvg rmsd_vs_start.xvg rmsd_vs_average.xvg rmsf_per_residue.xvg RESULTS_gmx_MMPBSA.h5 Fichiers/


echo -e "\nDynamics analysis completed!"
