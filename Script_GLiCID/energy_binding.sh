#!/bin/bash


#SBATCH --job-name=energy_binding                           # Name for your job
#SBATCH --comment="analyse de l'énergie de liaisons"        # Comment for your job
#SBATCH --mail-user=florent.boyer@etu.univ-nantes.fr        # Mail
#SBATCH --mail-type=all

#SBATCH --output=output_energy_binding.out          # Output file
#SBATCH --error=error_energy_binding.err            # Error file

#SBATCH --time=00-02:00:00        # Time limit
#SBATCH --nodes=1                 # How many nodes to run on
#SBATCH --ntasks=1                # How many tasks per node
#SBATCH --cpus-per-task=32        # Number of CPUs per task
#SBATCH --mem-per-cpu=1g          # Memory per CPU
#SBATCH --qos=quick               # Priority/Quality of service


# Command to run
module load guix
source ~/.bashrc

# Activate conda environment
conda activate mmpbsa

# First step: create the index file with the groups of interest
echo -e "ri 1-16\nname 17 Ligand\nri 17-365\nname 18 Receptor\nq" | gmx make_ndx -f md_0_1.tpr -o index.ndx

# Verify the content of the index file
#gmx make_ndx -n index.ndx

# Don't forget to put mmpbsa.in, md_0_1.tpr, md_0_1_noPBC.xtc, index.ndx, topol.top with topol_Protein_chain_A.itp and topol_Protein_chain_B.itp in the same directory as this script before running it!
# Run the gmx_MMPBSA command
gmx_MMPBSA -O -i mmpbsa.in -cs md_0_1.tpr -ct md_0_1_noPBC.xtc -ci index.ndx -cg 18 17 -cp topol.top -o FINAL_RESULTS_MMPBSA.dat -do DECOMP_RESULTS.dat -nogui
