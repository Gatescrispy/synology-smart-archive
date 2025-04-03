# Synology Smart Archive 🗄️

Une solution d'archivage intelligent pour les utilisateurs de Synology Drive sur macOS. Libérez automatiquement de l'espace disque tout en gardant vos fichiers facilement accessibles via des liens symboliques.

## 🌟 Caractéristiques

- **Archivage Automatique** : Déplace automatiquement les fichiers peu utilisés vers votre NAS
- **Accès Transparent** : Crée des liens symboliques pour un accès transparent aux fichiers
- **Économie d'Espace** : Libère l'espace sur votre Mac tout en gardant les fichiers synchronisés
- **Sécurité** : Gestion robuste des erreurs et système de logs détaillé
- **Configuration Flexible** : Personnalisez les règles d'archivage selon vos besoins

## 📋 Prérequis

- macOS 10.15 ou supérieur
- Synology Drive Client installé et configuré
- Un NAS Synology avec Synology Drive Server
- Accès en ligne de commande à votre Mac

## 🚀 Installation

```bash
# Cloner le repository
git clone https://github.com/Gatescrispy/synology-smart-archive.git
cd synology-smart-archive

# Lancer l'installation
./install.sh
```

## ⚙️ Configuration

1. Modifiez le fichier de configuration selon vos besoins :
```bash
vim ~/SynologyDrive/scripts/config.yaml
```

2. Paramètres principaux :
- `MIN_AGE_DAYS` : Âge minimum des fichiers à archiver (défaut : 180 jours)
- `SOURCE_DIR` : Dossier à surveiller (défaut : ~/SynologyDrive)
- `ARCHIVE_DIR` : Dossier d'archive (défaut : ~/SynologyDrive/archives)

## 📊 Utilisation

Le script s'exécute automatiquement chaque jour à 2h du matin. Pour une exécution manuelle :

```bash
~/SynologyDrive/scripts/archive_daily.sh
```

## 📝 Logs

Les logs sont disponibles dans :
- `~/SynologyDrive/.archive_log.txt` : Log détaillé
- `~/SynologyDrive/scripts/archive.log` : Sortie standard
- `~/SynologyDrive/scripts/archive.err` : Erreurs

## 🛠 Dépannage

Consultez notre [guide de dépannage](docs/troubleshooting.md) pour les problèmes courants.

## 🤝 Contribution

Les contributions sont les bienvenues ! Consultez notre [guide de contribution](CONTRIBUTING.md).

## 📄 Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- Communauté Synology
- Contributeurs du projet
- Utilisateurs qui partagent leurs retours

## 📞 Support

- Créez une issue sur GitHub
- Consultez notre [documentation](docs/)