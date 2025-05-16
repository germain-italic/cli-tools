#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
from collections import defaultdict

def read_file_lines(filepath):
    """Lire les lignes d'un fichier"""
    with open(filepath, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f.readlines()]

def main():
    # Vérifier les arguments
    if len(sys.argv) != 7:
        print("Usage: optimize_dirs.py filtered_local filtered_remote local_dirs remote_dirs output_local output_remote")
        sys.exit(1)
    
    # Récupérer les arguments
    filtered_local_path = sys.argv[1]
    filtered_remote_path = sys.argv[2]
    local_dirs_path = sys.argv[3]
    remote_dirs_path = sys.argv[4]
    optimized_local_path = sys.argv[5]
    optimized_remote_path = sys.argv[6]
    
    # Lire les données
    filtered_local_files = read_file_lines(filtered_local_path)
    filtered_remote_files = read_file_lines(filtered_remote_path)
    local_dirs = read_file_lines(local_dirs_path)
    remote_dirs = read_file_lines(remote_dirs_path)
    
    # -------- Optimisation améliorée pour les fichiers locaux (manquants sur NAS) --------
    
    # 1. Regrouper les fichiers par dossier
    folder_files = defaultdict(list)
    all_parent_dirs = set()
    
    for filepath in filtered_local_files:
        dir_path = os.path.dirname(filepath)
        folder_files[dir_path].append(filepath)
        
        # Collecter tous les dossiers parents pour une analyse complète
        current_dir = dir_path
        while current_dir:
            all_parent_dirs.add(current_dir)
            parent_dir = os.path.dirname(current_dir)
            if parent_dir == current_dir:  # Éviter les boucles infinies
                break
            current_dir = parent_dir
    
    # 2. Identifier les dossiers complets qui sont manquants
    missing_dirs = set()
    for dir_path in local_dirs:
        if dir_path in all_parent_dirs:
            missing_dirs.add(dir_path)
    
    # 3. Déterminer quels dossiers sont entièrement inclus dans les fichiers différents
    complete_dir_paths = set()
    for dir_path in missing_dirs:
        # Un dossier est complet si tous ses fichiers sont dans les différences
        # et qu'il n'a pas de sous-dossier dans les différences
        has_all_files = True
        dir_path_with_slash = dir_path + '/'
        
        # Vérifier s'il y a des sous-dossiers de ce dossier qui sont aussi dans les différences
        has_subdirs = False
        for other_dir in missing_dirs:
            if other_dir != dir_path and other_dir.startswith(dir_path_with_slash):
                has_subdirs = True
                break
        
        if has_all_files and not has_subdirs:
            complete_dir_paths.add(dir_path)
    
    # 4. Préparer la liste optimisée
    optimized_local = []
    processed_files = set()
    
    # D'abord, ajouter les dossiers complets
    for dir_path in sorted(complete_dir_paths):
        optimized_local.append(f'{dir_path} [DOSSIER]')
        
        # Marquer tous les fichiers de ce dossier comme traités
        for filepath in filtered_local_files:
            if filepath.startswith(dir_path + '/') or filepath == dir_path:
                processed_files.add(filepath)
    
    # Ensuite, ajouter les fichiers restants qui n'ont pas été traités
    for filepath in filtered_local_files:
        if filepath not in processed_files:
            # Vérifier si un dossier parent est déjà inclus
            is_covered = False
            current_dir = os.path.dirname(filepath)
            
            while current_dir:
                if f'{current_dir} [DOSSIER]' in optimized_local:
                    is_covered = True
                    break
                parent_dir = os.path.dirname(current_dir)
                if parent_dir == current_dir:  # Éviter les boucles infinies
                    break
                current_dir = parent_dir
            
            if not is_covered:
                optimized_local.append(filepath)
    
    # -------- Optimisation améliorée pour les fichiers distants (manquants en local) --------
    
    # Procéder de manière similaire pour les fichiers distants
    # 1. Regrouper les fichiers par dossier
    remote_folder_files = defaultdict(list)
    remote_all_parent_dirs = set()
    
    for filepath in filtered_remote_files:
        dir_path = os.path.dirname(filepath)
        remote_folder_files[dir_path].append(filepath)
        
        # Collecter tous les dossiers parents
        current_dir = dir_path
        while current_dir:
            remote_all_parent_dirs.add(current_dir)
            parent_dir = os.path.dirname(current_dir)
            if parent_dir == current_dir:
                break
            current_dir = parent_dir
    
    # 2. Identifier les dossiers complets qui sont manquants
    remote_missing_dirs = set()
    for dir_path in remote_dirs:
        if dir_path in remote_all_parent_dirs:
            remote_missing_dirs.add(dir_path)
    
    # 3. Déterminer quels dossiers sont entièrement inclus
    remote_complete_dir_paths = set()
    for dir_path in remote_missing_dirs:
        has_all_files = True
        dir_path_with_slash = dir_path + '/'
        
        has_subdirs = False
        for other_dir in remote_missing_dirs:
            if other_dir != dir_path and other_dir.startswith(dir_path_with_slash):
                has_subdirs = True
                break
        
        if has_all_files and not has_subdirs:
            remote_complete_dir_paths.add(dir_path)
    
    # 4. Préparer la liste optimisée
    optimized_remote = []
    remote_processed_files = set()
    
    # D'abord, ajouter les dossiers complets
    for dir_path in sorted(remote_complete_dir_paths):
        optimized_remote.append(f'{dir_path} [DOSSIER]')
        
        # Marquer tous les fichiers de ce dossier comme traités
        for filepath in filtered_remote_files:
            if filepath.startswith(dir_path + '/') or filepath == dir_path:
                remote_processed_files.add(filepath)
    
    # Ensuite, ajouter les fichiers restants
    for filepath in filtered_remote_files:
        if filepath not in remote_processed_files:
            # Vérifier si un dossier parent est déjà inclus
            is_covered = False
            current_dir = os.path.dirname(filepath)
            
            while current_dir:
                if f'{current_dir} [DOSSIER]' in optimized_remote:
                    is_covered = True
                    break
                parent_dir = os.path.dirname(current_dir)
                if parent_dir == current_dir:
                    break
                current_dir = parent_dir
            
            if not is_covered:
                optimized_remote.append(filepath)
    
    # Écrire les résultats optimisés
    with open(optimized_local_path, 'w', encoding='utf-8') as f:
        for item in optimized_local:
            f.write(f'{item}\n')
    
    with open(optimized_remote_path, 'w', encoding='utf-8') as f:
        for item in optimized_remote:
            f.write(f'{item}\n')
    
    print(f'Optimisation terminée: {len(optimized_local)} entrées locales et {len(optimized_remote)} entrées distantes')

if __name__ == "__main__":
    main()