pipeline {
    agent any

    environment {
        MOBILE_DIR = 'mobile'
    }

    stages {

        // ── Stage 1: Verificar que Flutter está instalado ─────────────────────
        stage('Setup Flutter') {
            steps {
                echo '─── Verificando entorno Flutter ───'
                sh '''
                    # Buscar flutter en las rutas más comunes
                    FLUTTER=""
                    for candidate in \
                        "$HOME/development/flutter/bin/flutter" \
                        "$HOME/flutter/bin/flutter" \
                        /opt/homebrew/bin/flutter \
                        /usr/local/bin/flutter \
                        flutter
                    do
                        if command -v "$candidate" > /dev/null 2>&1; then
                            FLUTTER="$candidate"
                            break
                        fi
                    done

                    if [ -z "$FLUTTER" ]; then
                        echo "ERROR: No se encontró Flutter. Instalalo en el agente de Jenkins."
                        exit 1
                    fi

                    echo "Flutter encontrado: $FLUTTER"
                    "$FLUTTER" --version
                '''
            }
        }

    }

    post {
        success {
            echo 'Pipeline completado correctamente.'
        }
        failure {
            echo 'Pipeline fallido — revisá el log.'
        }
    }
}
