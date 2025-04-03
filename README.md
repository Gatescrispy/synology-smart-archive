# Synology Smart Archive

Une application web pour gérer intelligemment l'archivage automatique des fichiers sur Synology Drive.

## Fonctionnalités

- Archivage automatique des fichiers selon leur âge
- Interface web intuitive pour gérer les archives
- Visualisation des fichiers archivés avec recherche
- Restauration facile des fichiers
- Statistiques d'archivage en temps réel
- Logs détaillés des opérations
- Configuration flexible des critères d'archivage

## Prérequis

- Python 3.8+
- Flask
- Synology Drive installé et configuré
- Accès en lecture/écriture au dossier Synology Drive

## Installation

1. Clonez le repository :
```bash
git clone https://github.com/Gatescrispy/synology-smart-archive.git
cd synology-smart-archive
```

2. Créez un environnement virtuel et installez les dépendances :
```bash
python -m venv venv
source venv/bin/activate  # Sur Unix/macOS
# ou
.\venv\Scripts\activate  # Sur Windows
pip install -r requirements.txt
```

3. Copiez le fichier de configuration exemple et ajustez-le :
```bash
cp config/default.conf.example config/default.conf
# Éditez config/default.conf avec vos paramètres
```

## Configuration

Éditez `config/default.conf` pour configurer :

- Le chemin vers votre dossier Synology Drive
- L'âge minimum des fichiers à archiver
- Les extensions et dossiers à exclure
- Les paramètres de logs et notifications

## Utilisation

1. Démarrez l'application :
```bash
python web/app.py
```

2. Accédez à l'interface web : http://localhost:5000

3. Utilisez les boutons pour :
   - Lancer l'archivage
   - Voir/cacher les fichiers archivés
   - Restaurer des fichiers spécifiques

## Sécurité

- Les fichiers de configuration contenant des informations sensibles sont exclus de Git
- Les chemins d'accès sont validés pour éviter les attaques par traversée de répertoire
- Les opérations de fichiers sont sécurisées

## Contribution

1. Fork le projet
2. Créez votre branche de fonctionnalité
3. Committez vos changements
4. Poussez vers la branche
5. Ouvrez une Pull Request

## Licence

MIT License - voir le fichier LICENSE pour plus de détails.