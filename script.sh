#!/bin/bash

# Configuration
SITE_DIR=~/Trombinoscope-digital
OUTPUT_FILE="$SITE_DIR/datas.json"
ASSETS_DIR="$SITE_DIR/assets"
LOG_FILE="$SITE_DIR/import.log"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Crée les répertoires nécessaires
mkdir -p "$SITE_DIR"
mkdir -p "$ASSETS_DIR/Trombinoscope"
mkdir -p "$ASSETS_DIR/Actu"
touch "$LOG_FILE"

# Détection de la clé USB
USB_MOUNT=$(lsblk -o NAME,MOUNTPOINT | grep -i media | awk '{print $2}' | head -n 1)

if [ -z "$USB_MOUNT" ]; then
    log "Erreur: Aucune clé USB détectée"
    exit 1
fi

log "Clé USB détectée à: $USB_MOUNT"

# Vérification des dossiers requis
TROMBI_DIR="$USB_MOUNT/Trombinoscope"
ACTU_DIR="$USB_MOUNT/Actu"

if [ ! -d "$TROMBI_DIR" ] || [ ! -d "$ACTU_DIR" ]; then
    log "Erreur: Structure de dossiers invalide sur la clé USB"
    log "Recherché: $TROMBI_DIR et $ACTU_DIR"
    exit 1
fi

# Copier les dossiers depuis la clé USB vers assets
log "Nettoyage des dossiers de destination..."
rm -rf "$ASSETS_DIR/Trombinoscope"/*
rm -rf "$ASSETS_DIR/Actu"/*

log "Copie des fichiers depuis la clé USB..."
cp -r "$TROMBI_DIR"/* "$ASSETS_DIR/Trombinoscope/"
cp -r "$ACTU_DIR"/* "$ASSETS_DIR/Actu/"

log "Création du fichier JSON..."

# Création du JSON - Début
cat > "$OUTPUT_FILE" << EOL
{
  "lastUpdate": "$(date '+%Y-%m-%d %H:%M:%S')",
  "services": [
EOL

# Traitement des services
FIRST_SERVICE=true
for SERVICE_DIR in "$TROMBI_DIR"/*; do
    if [ -d "$SERVICE_DIR" ]; then
        SERVICE_NAME=$(basename "$SERVICE_DIR")
        
        if [ "$FIRST_SERVICE" = true ]; then
            FIRST_SERVICE=false
        else
            echo "    }," >> "$OUTPUT_FILE"
        fi
        
        log "Traitement du service: $SERVICE_NAME"
        
        echo "    {" >> "$OUTPUT_FILE"
        echo "      \"name\": \"$SERVICE_NAME\"," >> "$OUTPUT_FILE"
        echo "      \"collaborateurs\": [" >> "$OUTPUT_FILE"
        
        FIRST_COLLAB=true
        for COLLAB_FILE in "$SERVICE_DIR"/*; do
            if [ -f "$COLLAB_FILE" ]; then
                FILENAME=$(basename "$COLLAB_FILE")
                NAME="${FILENAME%.*}"
                
                if [ "$FIRST_COLLAB" = true ]; then
                    FIRST_COLLAB=false
                else
                    echo "        }," >> "$OUTPUT_FILE"
                fi
                
                echo "        {" >> "$OUTPUT_FILE"
                echo "          \"nom\": \"$NAME\"," >> "$OUTPUT_FILE"
                echo "          \"photo\": \"assets/Trombinoscope/$SERVICE_NAME/$FILENAME\"" >> "$OUTPUT_FILE"
            fi
        done
        
        if [ "$FIRST_COLLAB" = false ]; then
            echo "        }" >> "$OUTPUT_FILE"
        fi
        echo "      ]" >> "$OUTPUT_FILE"
    fi
done

# Fermeture des services
if [ "$FIRST_SERVICE" = false ]; then
    echo "    }" >> "$OUTPUT_FILE"
fi

# Actualités
echo "  ]," >> "$OUTPUT_FILE"
echo "  \"actualites\": [" >> "$OUTPUT_FILE"

FIRST_ACTU=true
for ACTU_FILE in "$ACTU_DIR"/*; do
    if [ -f "$ACTU_FILE" ]; then
        FILENAME=$(basename "$ACTU_FILE")
        NAME="${FILENAME%.*}"
        EXT="${FILENAME##*.}"
        
        if [ "$FIRST_ACTU" = true ]; then
            FIRST_ACTU=false
        else
            echo "    }," >> "$OUTPUT_FILE"
        fi
        
        log "Traitement de l'actualité: $FILENAME"
        
        echo "    {" >> "$OUTPUT_FILE"
        echo "      \"titre\": \"$NAME\"," >> "$OUTPUT_FILE"
        echo "      \"type\": \"$EXT\"," >> "$OUTPUT_FILE"
        echo "      \"fichier\": \"assets/Actu/$FILENAME\"" >> "$OUTPUT_FILE"
    fi
done

# Fermeture des actualités et du JSON
if [ "$FIRST_ACTU" = false ]; then
    echo "    }" >> "$OUTPUT_FILE"
fi
echo "  ]" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

log "Traitement terminé. Fichier JSON créé: $OUTPUT_FILE"
log "Les fichiers ont été copiés vers: $ASSETS_DIR"

# Affichage d'un résumé
echo ""
echo "=== Résumé de l'importation ==="
echo "Dossier du site: $SITE_DIR"
echo "Fichier JSON créé: $OUTPUT_FILE"
echo "Détails du traitement: $LOG_FILE"
echo "==========================="