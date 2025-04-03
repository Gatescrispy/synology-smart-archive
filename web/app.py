from flask import Flask, render_template, jsonify, request
import os
import json
import subprocess
from datetime import datetime
from config import DevelopmentConfig, ProductionConfig

# Initialisation de l'application
app = Flask(__name__)

# Chargement de la configuration
if os.environ.get('FLASK_ENV') == 'production':
    app.config.from_object(ProductionConfig)
else:
    app.config.from_object(DevelopmentConfig)

# Configuration du logging
import logging
from logging.handlers import RotatingFileHandler

if not os.path.exists('logs'):
    os.makedirs('logs')

file_handler = RotatingFileHandler(app.config['LOG_FILE'], maxBytes=1024 * 1024, backupCount=10)
file_handler.setFormatter(logging.Formatter(app.config['LOG_FORMAT']))
file_handler.setLevel(logging.INFO)
app.logger.addHandler(file_handler)

# Configuration
SCRIPT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'scripts')
ARCHIVE_SCRIPT = os.path.join(SCRIPT_DIR, 'archive_daily.sh')
RESTORE_SCRIPT = os.path.join(SCRIPT_DIR, 'restore.sh')
CONFIG_FILE = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'config', 'default.conf')
LOGS_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/stats')
def stats():
    return jsonify(get_archive_stats())

@app.route('/api/logs')
def logs():
    return jsonify({'logs': get_recent_logs()})

@app.route('/api/files')
def list_files():
    try:
        archive_path = get_archive_path()
        if not archive_path or not os.path.exists(archive_path):
            return jsonify({'files': []})

        files = []
        for root, _, filenames in os.walk(archive_path):
            for filename in filenames:
                file_path = os.path.join(root, filename)
                try:
                    stats = os.stat(file_path)
                    relative_path = os.path.relpath(file_path, archive_path)
                    files.append({
                        'name': relative_path,
                        'size': stats.st_size,
                        'date': datetime.fromtimestamp(stats.st_mtime).strftime('%d/%m/%Y %H:%M')
                    })
                except OSError as e:
                    app.logger.error(f"Erreur lors de la lecture du fichier {file_path}: {str(e)}")
                    continue

        return jsonify({'files': files})
    except Exception as e:
        app.logger.error(f"Erreur lors de la liste des fichiers: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/archive', methods=['POST'])
def start_archive():
    try:
        app.logger.info("Démarrage de l'archivage...")
        
        script_path = os.path.abspath(ARCHIVE_SCRIPT)
        app.logger.info(f"Chemin du script: {script_path}")
        
        if not os.path.exists(script_path):
            app.logger.error(f"Script non trouvé: {script_path}")
            return jsonify({
                'success': False,
                'message': 'Script d\'archivage non trouvé'
            }), 500
            
        lock_file = "/tmp/synology_archive.lock"
        if os.path.exists(lock_file):
            try:
                with open(lock_file, 'r') as f:
                    pid = int(f.read().strip())
                if os.path.exists(f"/proc/{pid}"):
                    return jsonify({
                        'success': False,
                        'message': 'Un autre processus d\'archivage est déjà en cours'
                    }), 409
            except:
                pass
            
        try:
            result = subprocess.run(['bash', script_path], 
                                  capture_output=True, 
                                  text=True,
                                  cwd=os.path.dirname(script_path),
                                  timeout=60)
        except subprocess.TimeoutExpired:
            app.logger.error("Timeout lors de l'exécution du script d'archivage")
            if os.path.exists(lock_file):
                os.remove(lock_file)
            return jsonify({
                'success': False,
                'message': 'L\'opération a pris trop de temps'
            }), 504
            
        app.logger.info(f"Sortie standard: {result.stdout}")
        if result.stderr:
            app.logger.error(f"Erreur standard: {result.stderr}")
        
        output = result.stdout + result.stderr
        
        try:
            stats_file = os.path.join(LOGS_DIR, 'stats.json')
            current_stats = {}
            if os.path.exists(stats_file):
                with open(stats_file, 'r') as f:
                    current_stats = json.load(f)
            
            current_stats['last_run'] = datetime.now().astimezone().isoformat()
            
            with open(stats_file, 'w') as f:
                json.dump(current_stats, f)
        except Exception as e:
            app.logger.error(f"Erreur lors de la mise à jour des stats: {str(e)}")
        
        if "Aucun fichier trouvé à archiver" in output:
            return jsonify({
                'success': True,
                'message': 'Aucun fichier trouvé à archiver'
            })
        elif result.returncode == 0:
            return jsonify({
                'success': True,
                'message': 'Archivage terminé avec succès'
            })
        else:
            error_msg = next((line for line in output.split('\n') if '[ERROR]' in line), 
                           'Erreur inconnue lors de l\'archivage')
            app.logger.error(f"Erreur d'archivage: {error_msg}")
            return jsonify({
                'success': False,
                'message': error_msg
            }), 500
    except Exception as e:
        app.logger.error(f"Erreur lors de l'archivage: {str(e)}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

if __name__ == '__main__':
    app.run(debug=True)