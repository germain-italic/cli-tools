#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pandas as pd
import sys
import os
from datetime import datetime

def read_file_with_type(filepath, status, location):
    """Lire et analyser les fichiers avec leur type"""
    results = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if '[DOSSIER]' in line:
                    dir_name = line.replace(' [DOSSIER]', '')
                    results.append({
                        'Status': status,
                        'Location': location,
                        'Path': dir_name,
                        'Extension': 'N/A',
                        'Type': 'Directory'
                    })
                else:
                    ext = os.path.splitext(line)[1]
                    ext = ext[1:] if ext else 'aucune'
                    results.append({
                        'Status': status,
                        'Location': location,
                        'Path': line,
                        'Extension': ext,
                        'Type': 'File'
                    })
    except Exception as e:
        print(f'Erreur lors de la lecture du fichier {filepath}: {e}')
    return results

def adjust_columns_xlsxwriter(worksheet, df):
    """Ajuster les largeurs des colonnes pour xlsxwriter pour s'adapter exactement au contenu"""
    for i, col in enumerate(df.columns):
        # Calculer la largeur maximale pour cette colonne
        column_width = len(str(col)) + 2  # Largeur de l'en-tête avec un peu d'espace
        
        # Parcourir toutes les valeurs de cette colonne
        for value in df[col].astype(str):
            # Pour les valeurs longues, mesurer précisément leur largeur
            if len(value) > column_width:
                # Ajuster en fonction du type de contenu
                if col == 'Path':
                    # Pour les chemins de fichiers, on utilise une approche plus précise
                    # Le texte peut être plus dense que les caractères d'en-tête
                    value_width = len(value) * 0.9  # Facteur de conversion pour police proportionnelle
                else:
                    value_width = len(value) * 1.0
                
                column_width = max(column_width, value_width)
        
        # Ajustements spécifiques selon le type de colonne
        if col == 'Path':
            # Assurer une largeur minimale pour Path, mais privilégier le contenu réel
            column_width = max(column_width, 40)
        elif col == 'Extension':
            # Les extensions sont souvent courtes
            column_width = max(column_width, 10)
        elif col == 'Type' or col == 'Status' or col == 'Location':
            # Colonnes de type énumération
            column_width = max(column_width, 12)
        
        # Limiter la largeur maximale pour éviter les colonnes trop larges
        column_width = min(column_width, 120)
        
        # Ajouter un petit espace supplémentaire pour la lisibilité (1 caractère)
        column_width += 1
        
        # Définir la largeur de colonne exacte pour ce worksheet
        worksheet.set_column(i, i, column_width)

def main():
    # Vérifier les arguments
    if len(sys.argv) != 10:
        print("Usage: generate_report.py optimized_local optimized_remote filtered_local filtered_remote output_csv output_xlsx exclude_locally exclude_nas script_files")
        sys.exit(1)
    
    # Récupérer les arguments
    optimized_local_path = sys.argv[1]
    optimized_remote_path = sys.argv[2]
    filtered_local_path = sys.argv[3]
    filtered_remote_path = sys.argv[4]
    output_csv = sys.argv[5]
    output_xlsx = sys.argv[6]
    exclude_locally_path = sys.argv[7]
    exclude_nas_path = sys.argv[8]
    script_files_path = sys.argv[9]
    
    # Vérifier que les fichiers existent
    for path in [optimized_local_path, optimized_remote_path, filtered_local_path, filtered_remote_path]:
        if not os.path.exists(path):
            print(f"Erreur: Le fichier {path} n'existe pas.")
            sys.exit(1)
    
    # Lire les patterns d'exclusion
    with open(exclude_locally_path, 'r') as f:
        excluded_locally = f.read().strip()
    with open(exclude_nas_path, 'r') as f:
        excluded_on_nas = f.read().strip()
    
    script_files = ""
    if script_files_path and os.path.exists(script_files_path):
        with open(script_files_path, 'r') as f:
            script_files = f.read().strip()
    
    # Vérifier si les bibliothèques Excel sont disponibles
    excel_engine = None
    try:
        import xlsxwriter
        excel_engine = 'xlsxwriter'
        print('Utilisation du moteur xlsxwriter pour Excel (plus fiable)')
    except ImportError:
        try:
            import openpyxl
            excel_engine = 'openpyxl'
            print('Utilisation du moteur openpyxl pour Excel')
        except ImportError:
            print('Aucun moteur Excel disponible. Création uniquement du CSV.')
    
    # Lire les fichiers optimisés
    local_optimized = read_file_with_type(optimized_local_path, 'Missing on NAS', 'Local')
    remote_optimized = read_file_with_type(optimized_remote_path, 'Missing Locally', 'NAS')
    
    # Lire les fichiers complets (non optimisés)
    local_full = []
    with open(filtered_local_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            ext = os.path.splitext(line)[1]
            ext = ext[1:] if ext else 'aucune'
            local_full.append({
                'Status': 'Missing on NAS',
                'Location': 'Local',
                'Path': line,
                'Extension': ext,
                'Type': 'File'
            })
            
    remote_full = []
    with open(filtered_remote_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            ext = os.path.splitext(line)[1]
            ext = ext[1:] if ext else 'aucune'
            remote_full.append({
                'Status': 'Missing Locally',
                'Location': 'NAS',
                'Path': line,
                'Extension': ext,
                'Type': 'File'
            })
    
    # Créer les DataFrames
    df_optimized = pd.DataFrame(local_optimized + remote_optimized)
    df_full = pd.DataFrame(local_full + remote_full)
    
    # Créer des sous-ensembles pour chaque type
    missing_on_nas = df_optimized[df_optimized['Status'] == 'Missing on NAS'] if not df_optimized.empty else pd.DataFrame()
    missing_locally = df_optimized[df_optimized['Status'] == 'Missing Locally'] if not df_optimized.empty else pd.DataFrame()
    missing_on_nas_full = df_full[df_full['Status'] == 'Missing on NAS'] if not df_full.empty else pd.DataFrame()
    missing_locally_full = df_full[df_full['Status'] == 'Missing Locally'] if not df_full.empty else pd.DataFrame()
    
    # Créer le résumé
    current_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    summary_data = {
        'Category': [
            f'Rapport généré le: {current_date}',
            'Files only on Local (optimized)', 
            'Files only on NAS (optimized)', 
            'Files only on Local (full)', 
            'Files only on NAS (full)', 
            'Total differences (optimized)',
            'Total differences (full)',
            '----- Excluded Extensions -----',
            'Extensions excluded from Local (Missing on NAS)',
            'Extensions excluded from NAS (Missing Locally)',
            '----- Excluded Script Files -----',
            'Files excluded from comparison'
        ],
        'Count/Value': [
            '',
            len(missing_on_nas), 
            len(missing_locally), 
            len(missing_on_nas_full), 
            len(missing_locally_full), 
            len(df_optimized),
            len(df_full),
            '',
            excluded_on_nas,
            excluded_locally,
            '',
            script_files
        ]
    }
    summary_df = pd.DataFrame(summary_data)
    
    # Créer le résumé par extension
    ext_summary_list = []
    
    if not missing_on_nas_full.empty and 'Extension' in missing_on_nas_full.columns:
        extensions = missing_on_nas_full['Extension'].value_counts().reset_index()
        extensions.columns = ['Extension', 'Count']
        extensions['Location'] = 'Local'
        ext_summary_list.append(extensions)
    
    if not missing_locally_full.empty and 'Extension' in missing_locally_full.columns:
        extensions = missing_locally_full['Extension'].value_counts().reset_index()
        extensions.columns = ['Extension', 'Count']
        extensions['Location'] = 'NAS'
        ext_summary_list.append(extensions)
    
    ext_summary = pd.concat(ext_summary_list) if ext_summary_list else pd.DataFrame(columns=['Extension', 'Count', 'Location'])
    
    # Créer un CSV principal avec toutes les différences
    try:
        # Fichier CSV principal
        df_full.to_csv(output_csv, index=False)
        print(f'Fichier CSV principal créé: {output_csv}')
    except Exception as e:
        print(f'Erreur lors de la création du fichier CSV: {e}')
    
    # Si aucun moteur Excel n'est disponible, terminer ici
    if not excel_engine:
        print('Aucun moteur Excel disponible, traitement terminé.')
        sys.exit(0)
    
    # Créer le fichier Excel
    try:
        print(f'Création du fichier Excel avec {excel_engine}...')
        
        # Supprimer un fichier Excel existant
        if os.path.exists(output_xlsx):
            os.remove(output_xlsx)
        
        # Créer le fichier Excel directement sans utiliser de fichier temporaire
        with pd.ExcelWriter(output_xlsx, engine=excel_engine) as writer:
            # Écrire les feuilles
            summary_df.to_excel(writer, sheet_name='Summary', index=False)
            if not ext_summary.empty:
                ext_summary.to_excel(writer, sheet_name='Extensions', index=False)
            if not df_optimized.empty:
                df_optimized.to_excel(writer, sheet_name='Optimized', index=False)
            if not df_full.empty:
                df_full.to_excel(writer, sheet_name='All Differences', index=False)
            if not missing_on_nas.empty:
                missing_on_nas.to_excel(writer, sheet_name='Missing on NAS', index=False)
            if not missing_locally.empty:
                missing_locally.to_excel(writer, sheet_name='Missing Locally', index=False)
            
            # Ajuster automatiquement la largeur des colonnes si c'est xlsxwriter
            if excel_engine == 'xlsxwriter':
                print('Ajustement automatique des colonnes avec xlsxwriter...')
                
                # Ajuster chaque feuille
                if not summary_df.empty:
                    adjust_columns_xlsxwriter(writer.sheets['Summary'], summary_df)
                if not ext_summary.empty:
                    adjust_columns_xlsxwriter(writer.sheets['Extensions'], ext_summary)
                if not df_optimized.empty:
                    adjust_columns_xlsxwriter(writer.sheets['Optimized'], df_optimized)
                if not df_full.empty:
                    adjust_columns_xlsxwriter(writer.sheets['All Differences'], df_full)
                if not missing_on_nas.empty:
                    adjust_columns_xlsxwriter(writer.sheets['Missing on NAS'], missing_on_nas)
                if not missing_locally.empty:
                    adjust_columns_xlsxwriter(writer.sheets['Missing Locally'], missing_locally)
        
        if os.path.exists(output_xlsx):
            print(f'Fichier Excel créé avec succès: {output_xlsx}')
            print(f'Taille: {os.path.getsize(output_xlsx)} octets')
        else:
            print('Erreur: Fichier Excel non créé')
            
    except Exception as e:
        print(f'Erreur lors de la création du fichier Excel: {e}')
        print(f'Détail de l\'erreur: {type(e).__name__}: {str(e)}')
        print('Utilisez le fichier CSV à la place.')

if __name__ == "__main__":
    main()