# Synology Smart Archive

Un outil intelligent d'archivage automatique pour Synology Drive sur macOS.

## Fonctionnalités

- Archivage automatique des fichiers non utilisés depuis 180 jours
- Conservation de l'accès aux fichiers via des liens symboliques
- Rotation automatique des logs
- Statistiques d'utilisation
- Interface de restauration simple
- Gestion intelligente de l'espace disque
- Protection contre les erreurs

## Prérequis

- macOS
- Synology Drive Client
- jq (pour la gestion des statistiques)

## Installation

1. Clonez le dépôt :
```bash
git clone https://github.com/Gatescrispy/synology-smart-archive.git
cd synology-smart-archive
```

2. Rendez les scripts exécutables :
```bash
chmod +x scripts/*.sh scripts/lib/*.sh
```

3. Configurez le chemin de votre Synology Drive dans `config/default.conf`

## Utilisation

### Archivage automatique

Le script s'exécute automatiquement chaque jour à 2h du matin. Pour un lancement manuel :

```bash
./scripts/archive_daily.sh
```

### Restauration

Pour lister les fichiers archivés :
```bash
./scripts/restore.sh -l
```

Pour restaurer un fichier spécifique :
```bash
./scripts/restore.sh -r "chemin/vers/fichier"
```

Pour tout restaurer :
```bash
./scripts/restore.sh -a
```

## Configuration

Modifiez `config/default.conf` pour personnaliser :

- L'âge minimum des fichiers à archiver
- Les extensions à exclure
- Les paramètres de rotation des logs
- Les limites de ressources

## Logs et Statistiques

- Logs principaux : `logs/archive.log`
- Logs d'erreurs : `logs/error.log`
- Statistiques : `logs/stats.json`

## Sécurité

- Validation des chemins de fichiers
- Vérification des permissions
- Protection contre les exécutions simultanées
- Gestion des erreurs avec limite maximale

## Licence

MIT License - voir le fichier `LICENSE` pour plus de détails.