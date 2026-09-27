#!/usr/bin/env python3

import sys
import re

"""
Automatisation des scripts "find_atoms.py", "gro_to_pdb.py", "gro_to_ndx.py" et "fix_ndx.py".
Voir les fichier spécifiques pour plus d'info sur leur fonction exacte.
ATTENTION ne fonctionne qu'avec TBL1R (166-514), et que si le peptide à été modélisé en premier!
"""

def find_atoms_numbers(gro_file):
    
    with open(gro_file, "r") as f:
        lines = f.readlines()
    
    # Supprime le header et la dernière ligne
    atom_lines = lines[2:-1]
    atoms = 0
    
    for line in atom_lines:
        atoms += 1
        if line.startswith("  166ARG      N"):
            print(f"Le peptide contient {atoms-1} atomes.")
            return(int(atoms-1))
        
        
def convert_gro_to_pdb(gro_file, pdb_file, peptide_index):
    excluded_resnames = {"SOL", "HOH", "NA", "CL", "K", "CA", "MG", "ZN"}

    with open(gro_file, "r") as f:
        lines = f.readlines()

    # Supprime le header et la dernière ligne
    atom_lines = lines[2:-1]

    with open(pdb_file, "w") as f_out:
        atom_index = 1
        for line in atom_lines:
            res_num = int(line[0:5])
            res_name = line[5:10].strip()
            atom_name = line[10:15].strip()
            #gro_atom_num = int(line[15:20])
            x = float(line[20:28]) * 10  # nm en Å
            y = float(line[28:36]) * 10
            z = float(line[36:44]) * 10

            if res_name in excluded_resnames:
                chain_id = " "
            elif atom_index <= peptide_index:
                chain_id = "A"  # Peptide
            else:
                chain_id = "B"  # Protein

            pdb_line = (
                f"ATOM  {atom_index:5d} {atom_name:^4} {res_name:>3} {chain_id}"
                f"{res_num:4d}    {x:8.3f}{y:8.3f}{z:8.3f}  1.00  0.00\n"
            )
            f_out.write(pdb_line)
            atom_index += 1

        f_out.write("END\n")

    print(f"PDB écrit dans: {pdb_file}")
    
    
def convert_gro_to_ndx(gro_file, ndx_file, peptide_index):
    excluded_resnames = {"SOL", "HOH", "NA", "CL", "K", "CA", "MG", "ZN"}

    with open(gro_file, "r") as f:
        lines = f.readlines()

    # Supprime le header et la dernière ligne
    atom_lines = lines[2:-1]

    peptide_atoms = []
    protein_atoms = []
    solvent_atoms = []

    atom_index = 1
    for line in atom_lines:
        res_name = line[5:10].strip()

        if res_name in excluded_resnames:
            solvent_atoms.append(atom_index)
        elif atom_index <= peptide_index:
            peptide_atoms.append(atom_index)
        else:
            protein_atoms.append(atom_index)

        atom_index += 1

    with open(ndx_file, "w") as f:
        f.write("[ Peptide ]\n")
        f.write(" ".join(map(str, peptide_atoms)) + "\n\n")
        f.write("[ Protein ]\n")
        f.write(" ".join(map(str, protein_atoms)) + "\n\n")
        f.write("[ Solvent ]\n")
        f.write(" ".join(map(str, solvent_atoms)) + "\n")

    print(f"NDX écrit dans: {ndx_file}")


def fix_ndx(ndx_file, ndx_fixed):

    groups = []
    # Ouverture et correction du fichiers .ndx
    with open(ndx_file, "r", encoding="utf-8", errors="replace") as f:
        current = None
        for line in f:
            m = re.match(r'^\s*\[\s*(.+?)\s*\]\s*$', line)
            if m:
                current = m.group(1)
                groups.append((current, []))
            else:
                if current is not None:
                    nums = re.findall(r'\d+', line)
                    groups[-1][1].extend(int(n) for n in nums)

    # Tri chaque groupe et supprime les duplicats
    for i,(name, lst) in enumerate(groups):
        uniq_sorted = sorted(set(lst))
        groups[i] = (name, uniq_sorted)

    # Création du groupe Protein_Peptide si Protein et Peptide existe
    names = [g[0] for g in groups]
    if "Protein" in names and "Peptide" in names:
        prot = groups[names.index("Protein")][1]
        pept = groups[names.index("Peptide")][1]
        union = sorted(set(prot) | set(pept))
        groups.append(("Protein_Peptide", union))

    # Sauvegarde dans un nouveau fichier .ndx avec 15 indices max par lignes (GROMACS default wrapping)
    with open(ndx_fixed, "w", encoding="utf-8") as f:
        for name, lst in groups:
            f.write("[ {} ]\n".format(name))
            for i in range(0, len(lst), 15):
                chunk = lst[i:i+15]
                f.write(" ".join(str(x) for x in chunk) + "\n")
            f.write("\n")
    
    print(f"NDX corrigé écrit dans: {ndx_fixed} avec {len(groups)} groupes.")
    
    
file = "md_0_1"
peptide_count = find_atoms_numbers(f"{file}.gro")

convert_gro_to_pdb(f"{file}.gro", f"{file}.pdb", peptide_count)
convert_gro_to_ndx(f"{file}.gro", f"{file}.ndx", peptide_count)
#fix_ndx(f"{file}.ndx", f"{file}_fixed.ndx")
