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
    exit 1
fi

# Copier les dossiers depuis la clé USB vers assets
log "Copie des dossiers vers assets..."
rm -rf "$ASSETS_DIR/Trombinoscope"/*  # Nettoyer le dossier existant
rm -rf "$ASSETS_DIR/Actu"/*           # Nettoyer le dossier existant
cp -r "$TROMBI_DIR"/* "$ASSETS_DIR/Trombinoscope/"
cp -r "$ACTU_DIR"/* "$ASSETS_DIR/Actu/"

# Création du JSON
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

if [ "$FIRST_SERVICE" = false ]; then
    echo "    }" >> "$OUTPUT_FILE"
fi

echo "  ]," >> "$OUTPUT_FILE"
echo "  \"actualites\": [" >> "$OUTPUT_FILE"

# Traitement des actualités
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

if [ "$FIRST_ACTU" = false ]; then
    echo "    }" >> "$OUTPUT_FILE"
fi

echo "  ]" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

log "Traitement terminé. Fichier JSON créé: $OUTPUT_FILE"

# Fonction pour détecter l'environnement de bureau
get_desktop_environment() {
    if [ -n "$DISPLAY" ]; then
        if [ -n "$GNOME_DESKTOP_SESSION_ID" ] || [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
            echo "GNOME"
        elif [ "$XDG_CURRENT_DESKTOP" = "LXDE" ]; then
            echo "LXDE"
        else
            echo "UNKNOWN"
        fi
    else
        echo "NO_DISPLAY"
    fi
}

# Fermer tous les navigateurs en cours
log "Fermeture des navigateurs existants..."
pkill chromium
pkill chromium-browser
pkill firefox
sleep 2

# Définir le chemin de la page web
WEB_PAGE="$SITE_DIR/index.html"

# Vérifier que la page existe
if [ ! -f "$WEB_PAGE" ]; then
    log "Erreur: Page web non trouvée: $WEB_PAGE"
    exit 1
fi

# Déterminer l'environnement de bureau
DE=$(get_desktop_environment)
log "Environnement de bureau détecté: $DE"

# Lancer le navigateur en plein écran
case $DE in
    "GNOME")
        # Pour GNOME
        export DISPLAY=:0
        chromium-browser --kiosk --start-fullscreen "$WEB_PAGE" &
        ;;
    "LXDE")
        # Pour Raspberry Pi OS avec LXDE (plus commun)
        export DISPLAY=:0
        chromium-browser --kiosk --disable-restore-session-state --noerrdialogs \
            --disable-translate --no-first-run --fast --fast-start \
            --disable-infobars --disable-features=TranslateUI \
            --disable-session-crashed-bubble --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' \
            --disable-component-update \
            --start-fullscreen "$WEB_PAGE" &
        ;;
    *)
        # Fallback générique
        export DISPLAY=:0
        chromium-browser --kiosk "$WEB_PAGE" &
        ;;
esac

# Attendre que le navigateur se lance
sleep 3

# Si on utilise LXDE (Raspberry Pi OS), on peut aussi cacher le curseur
if [ "$DE" = "LXDE" ]; then
    unclutter -idle 0.1 -root &
fi

# Configuration supplémentaire pour empêcher la mise en veille de l'écran
xset s off
xset -dpms
xset s noblank

log "Page web lancée en plein écran"