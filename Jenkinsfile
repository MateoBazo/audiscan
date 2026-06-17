pipeline {
    agent any

    environment {
        MOBILE_DIR = 'mobile'
        FLUTTER = '/opt/homebrew/bin/flutter'
    }

    stages {

        stage('Setup Flutter') {
            steps {
                echo '─── Verificando entorno Flutter ───'
                sh '"$FLUTTER" --version'
                sh '"$FLUTTER" pub get --directory=$MOBILE_DIR'
            }
        }

        stage('Test - Login Screen') {
            steps {
                echo '─── Ejecutando tests del Login ───'
                sh '''
                    cd $MOBILE_DIR
                    "$FLUTTER" test test/features/auth/login_screen_test.dart -v
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
