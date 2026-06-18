pipeline {
    agent any

    environment {
        MOBILE_DIR = 'mobile'
        FLUTTER = '/opt/homebrew/bin/flutter'
        DART = '/opt/homebrew/bin/dart'
    }

    stages {

        stage('Setup Flutter') {
            steps {
                echo 'Verificando entorno Flutter'
                sh '"$FLUTTER" --version'
                sh '"$FLUTTER" pub get --directory=$MOBILE_DIR'
                sh '"$DART" pub global activate junitreport'
            }
        }

        stage('Setup Backend') {
            steps {
                echo 'Configurando entorno Python'
                sh '''
                    cd backend
                    python3 -m venv venv
                    venv/bin/pip install --upgrade pip --quiet
                    venv/bin/pip install -r requirements-test.txt --quiet
                '''
            }
        }

        stage('Test - Backend (pytest)') {
            steps {
                echo 'Ejecutando tests unitarios del backend'
                sh '''
                    cd backend
                    venv/bin/python -m pytest tests/ -v --tb=short \
                        --html=reporte-backend.html \
                        --self-contained-html
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'backend',
                        reportFiles: 'reporte-backend.html',
                        reportName: 'Reporte Backend'
                    ])
                }
            }
        }

        stage('Test - Frontend (Flutter)') {
            steps {
                echo 'Ejecutando tests del Login'
                sh '''
                    mkdir -p $MOBILE_DIR/assets/images $MOBILE_DIR/assets/icons $MOBILE_DIR/assets/fonts
                    export PATH="/opt/homebrew/bin:$HOME/.pub-cache/bin:$PATH"
                    set -o pipefail
                    cd $MOBILE_DIR
                    "$FLUTTER" test test/features/auth/login_screen_test.dart --machine | tojunit --output flutter-report.xml
                '''
                sh 'backend/venv/bin/python -m junit2html mobile/flutter-report.xml mobile/reporte-frontend.html'
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'mobile',
                        reportFiles: 'reporte-frontend.html',
                        reportName: 'Reporte Frontend'
                    ])
                }
            }
        }

    }

    post {
        always {
            archiveArtifacts artifacts: 'backend/reporte-backend.html, mobile/reporte-frontend.html', allowEmptyArchive: true
        }
        success {
            echo 'Pipeline completado correctamente.'
        }
        failure {
            echo 'Pipeline fallido'
        }
    }
}
