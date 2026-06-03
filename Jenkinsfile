pipeline {
    agent any

    environment {
        // Ruta al backend dentro del repo
        BACKEND_DIR = 'backend'
        // Nombre del virtualenv que Jenkins creará
        VENV_DIR    = 'venv_jenkins'
    }

    stages {

        // ── Stage 1: Encontrar Python 3.12 e instalar dependencias ────────────
        stage('Setup') {
            steps {
                echo '─── Configurando entorno Python ───'
                sh '''
                    # Buscar python3.12 en las rutas más comunes de pyenv y Homebrew
                    PYTHON=""
                    for candidate in \
                        "$HOME/.pyenv/versions/3.12.7/bin/python3" \
                        "$HOME/.pyenv/shims/python3" \
                        /opt/homebrew/bin/python3.12 \
                        /usr/local/bin/python3.12 \
                        python3.12 \
                        python3
                    do
                        if command -v "$candidate" > /dev/null 2>&1; then
                            PYTHON="$candidate"
                            break
                        fi
                    done

                    if [ -z "$PYTHON" ]; then
                        echo "ERROR: No se encontró Python 3.12. Instálalo con pyenv o Homebrew."
                        exit 1
                    fi

                    echo "Python encontrado: $PYTHON"
                    "$PYTHON" --version

                    # Crear virtualenv limpio en el directorio backend
                    cd ${BACKEND_DIR}
                    "$PYTHON" -m venv ${VENV_DIR}

                    # Instalar solo las dependencias necesarias para los tests
                    # (evita instalar tensorflow y otras libs pesadas innecesarias)
                    ./${VENV_DIR}/bin/pip install --upgrade pip --quiet
                    ./${VENV_DIR}/bin/pip install \
                        fastapi==0.115.0 \
                        pydantic==2.8.2 \
                        pydantic-settings==2.4.0 \
                        "python-jose[cryptography]==3.3.0" \
                        "passlib[bcrypt]==1.7.4" \
                        python-multipart==0.0.9 \
                        email-validator==2.3.0 \
                        httpx==0.27.2 \
                        python-dotenv==1.0.1 \
                        "sqlalchemy[asyncio]==2.0.35" \
                        asyncpg==0.29.0 \
                        pytest==8.3.3 \
                        pytest-asyncio==0.23.8 \
                        pytest-html==4.1.1 \
                        --quiet
                '''
            }
        }

        // ── Stage 2: Correr los tests ─────────────────────────────────────────
        stage('Test') {
            steps {
                echo '─── Ejecutando suite de tests ───'
                sh '''
                    cd ${BACKEND_DIR}

                    # Crear .env mínimo para que la config no falle en tests
                    if [ ! -f .env ]; then
                        echo "SUPABASE_URL=http://localhost"            >  .env
                        echo "SUPABASE_ANON_KEY=test_anon_key"          >> .env
                        echo "SUPABASE_SERVICE_ROLE_KEY=test_srole_key" >> .env
                        echo "DATABASE_URL=postgresql+asyncpg://u:p@localhost/db" >> .env
                        echo "ENVIRONMENT=test"                         >> .env
                    fi

                    # Ejecutar pytest:
                    #   --tb=short    → tracebacks cortos en terminal
                    #   -v            → detalle de cada test en terminal
                    #   --html        → reporte HTML
                    #   --self-contained-html → HTML sin dependencias externas
                    #   --junitxml    → reporte XML para el plugin JUnit de Jenkins
                    ./${VENV_DIR}/bin/pytest tests/ \
                        -v \
                        --tb=short \
                        --html=reporte_tests.html \
                        --self-contained-html \
                        --junitxml=reporte_junit.xml
                '''
            }
            // Publicar resultados JUnit en la interfaz de Jenkins
            post {
                always {
                    junit 'backend/reporte_junit.xml'
                }
            }
        }

        // ── Stage 3: Publicar reporte HTML ────────────────────────────────────
        stage('Publish Report') {
            steps {
                echo '─── Publicando reporte HTML ───'
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing:          false,
                        alwaysLinkToLastBuild: true,
                        keepAll:               true,
                        reportDir:             'backend',
                        reportFiles:           'reporte_tests.html',
                        reportName:            'AudiScan — Reporte de Tests',
                        reportTitles:          'Resultados pytest'
                    ])
                }
            }
        }
    }

    // ── Notificación final en consola ─────────────────────────────────────────
    post {
        success {
            echo 'Pipeline completado — todos los tests pasaron.'
        }
        failure {
            echo 'Pipeline fallido — revisa los tests en el reporte HTML.'
        }
    }
}