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
                    venv/bin/python -m pytest tests/ -v --tb=short --junit-xml=pytest-report.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'backend/pytest-report.xml'
                }
            }
        }

        stage('Test - Frontend (Flutter)') {
            steps {
                echo 'Ejecutando tests del Login'
                sh '''
                    export PATH="/opt/homebrew/bin:$HOME/.pub-cache/bin:$PATH"
                    set -o pipefail
                    cd $MOBILE_DIR
                    "$FLUTTER" test test/features/auth/login_screen_test.dart --machine | tojunit --output flutter-report.xml
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'mobile/flutter-report.xml'
                }
            }
        }

    }

    post {
        success {
            echo 'Pipeline completado correctamente.'
        }
        failure {
            echo 'Pipeline fallido'
        }
    }
}
